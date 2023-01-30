CREATE VIEW [Roadside].[vwFleetManagers]

AS

WITH MostRecent AS (
	SELECT 
		VPRE.EventID, 
		VPRE.VehicleID, 
		VPRE.VehicleRoleTypeID, 
		MAX(VPRE.FromDate) AS FromDate
	FROM [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE		
	INNER JOIN [$(SampleDB)].Vehicle.VehicleRoleTypes VRT ON VRT.VehicleRoleTypeID = VPRE.VehicleRoleTypeID
	WHERE VRT.VehicleRoleType = 'Fleet Manager'
	GROUP BY VPRE.EventID, 
			VPRE.VehicleID, 
			VPRE.VehicleRoleTypeID
)
SELECT
	VPRE.VehicleID, 
	VPRE.PartyID, 
	VPRE.EventID, 
	VPRE.VehicleRoleTypeID, 
	CASE WHEN P.PartyID IS NOT NULL THEN 1 ELSE 0 END AS Person, 
	CASE WHEN O.PartyID IS NOT NULL THEN 1 ELSE 0 END AS Organisation
FROM [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE
INNER JOIN MostRecent MR ON MR.EventID = VPRE.EventID
						AND MR.VehicleID = VPRE.VehicleID
						AND MR.VehicleRoleTypeID = VPRE.VehicleRoleTypeID
						AND MR.FromDate = VPRE.FromDate
LEFT JOIN [$(SampleDB)].Party.People P ON P.PartyID = VPRE.PartyID	
LEFT JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = VPRE.PartyID
