﻿CREATE VIEW [IAssistance].[vwMatchIAssistanceParties]
AS

WITH CTE_MostRecent AS (
	-- THIS RETURNS THE MOST RECENT EVENT OF ANY KIND FOR THIS VEHICLE THAT OCCURED BEFORE THE IASSISTANCE EVENT
	SELECT 
		IE.MatchedODSVehicleID AS VehicleID, 
		MAX(CASE
				WHEN ET.EventCategory = 'Sales' THEN COALESCE(E.EventDate, R.RegistrationDate)
				ELSE E.EventDate
		END) AS EventDate
	FROM IAssistance.IAssistanceEvents IE
	INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.VehicleID = IE.MatchedODSVehicleID
	INNER JOIN [$(SampleDB)].Event.Events E ON VPRE.EventID = E.EventID
	INNER JOIN [$(SampleDB)].Event.vwEventTypes ET ON E.EventTypeID = ET.EventTypeID
	LEFT JOIN [$(SampleDB)].Vehicle.VehicleRegistrationEvents VRE
		INNER JOIN [$(SampleDB)].Vehicle.Registrations R ON R.RegistrationID = VRE.RegistrationID
	ON VRE.VehicleID = VPRE.VehicleID
	AND COALESCE(R.ThroughDate, '31 December 9999') > CURRENT_TIMESTAMP
	WHERE CASE
			WHEN ET.EventCategory = 'Sales' THEN COALESCE(E.EventDate, R.RegistrationDate)
			ELSE E.EventDate
		END <= IE.IAssistanceCallCloseDate
	AND IE.DateTransferredToVWT IS NULL
	AND ISNULL(IE.MatchedODSVehicleID, 0) > 0
	AND (   ISNULL(IE.MatchedODSPersonID, 0) = 0 
		 OR ISNULL(IE.MatchedODSOrganisationID, 0) = 0			-- BUG 12470 - 21-03-2016 - Change to ensure both Person and Organisation populated on records 
		)														--                          where we are just doing VIN matching. See proc: Roadside.uspMatchParties
	GROUP BY IE.MatchedODSVehicleID
),
CTE_Events AS (
	-- THIS RETURNS THE HIGHEST EVENT ID FOR EVENTS THAT PERTAIN TO THIS VEHICLE AND OCCURED ON THIS DATE 
	SELECT 
		VPRE.VehicleID, 
		CASE
			WHEN ET.EventCategory = 'Sales' THEN COALESCE(E.EventDate, R.RegistrationDate)
			ELSE E.EventDate
		END AS EventDate,
		MAX(VPRE.EventID) AS EventID
	FROM [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE
	INNER JOIN [$(SampleDB)].Event.Events E ON VPRE.EventID = E.EventID
	INNER JOIN [$(SampleDB)].Event.vwEventTypes ET ON ET.EventTypeID = E.EventTypeID
	LEFT JOIN [$(SampleDB)].Vehicle.VehicleRegistrationEvents VRE
		INNER JOIN [$(SampleDB)].Vehicle.Registrations R ON R.RegistrationID = VRE.RegistrationID
	ON VRE.VehicleID = VPRE.VehicleID
	AND COALESCE(R.ThroughDate, '31 December 9999') > CURRENT_TIMESTAMP				
	GROUP BY VPRE.VehicleID, 
			CASE
				WHEN ET.EventCategory = 'Sales' THEN COALESCE(E.EventDate, R.RegistrationDate)
				ELSE E.EventDate
			END
)
,CTE_WithOrderCols
AS (
-- Adds in columns required to ensure we identify the most appropriate Person or Organisation
SELECT 	MR.VehicleID, 
		MR.EventDate, 	
		E.EventID, 
		VPRE.PartyID,
		VPRE.FromDate,
		CASE WHEN O.PartyID IS NOT NULL THEN 'O'
			 WHEN P.PartyID IS NOT NULL THEN 'P'
			 ELSE '?'
			 END AS PartyType,
		CASE VRT.VehicleRoleType WHEN 'Principle Driver' THEN 1
						 WHEN 'Registered Owner' THEN 2
						 WHEN 'Purchaser'		 THEN 3
						 WHEN 'Other Driver'	 THEN 4
						 WHEN 'Fleet Manager'	 THEN 5
						 ELSE 6 
						 END AS VehicleRoleTypeOrderID,
		O.OrganisationName,
		P.LastName
FROM CTE_MostRecent MR
INNER JOIN CTE_Events E ON E.VehicleID = MR.VehicleID
					AND E.EventDate = MR.EventDate
INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE	ON E.EventID = VPRE.EventID
														AND E.VehicleID = VPRE.VehicleID
INNER JOIN [$(SampleDB)].Vehicle.VehicleRoleTypes VRT ON VRT.VehicleRoleTypeID = VPRE.VehicleRoleTypeID
LEFT JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = VPRE.PartyID
LEFT JOIN [$(SampleDB)].Party.People P ON P.PartyID = VPRE.PartyID
)
,CTE_VehiclePartiesOrdered
AS (
-- Use ordering columns and from date to put Persons and Organisations in order of most appropriate
SELECT VehicleID, EventDate, EventID, FromDate, PartyType, 
		PartyID, OrganisationName, LastName,
		ROW_NUMBER() OVER(PARTITION BY VehicleID, EventID, PartyType ORDER BY VehicleRoleTypeOrderID ASC, FromDate DESC) As RowID
FROM CTE_WithOrderCols
)
SELECT VehicleID, EventDate, EventID, PartyID, PartyType, 
		ISNULL(OrganisationName, '') AS OrganisationName, 
		ISNULL(LastName, '') LastName
FROM CTE_VehiclePartiesOrdered
WHERE RowID = 1  -- take only most appropriate Person and/or Org, if they exist. 
