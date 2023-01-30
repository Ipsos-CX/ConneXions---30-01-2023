CREATE VIEW Warranty.vwMatchWarrantyParties

AS

	/*
		Purpose:	Find the latest party attached to a vehicle so we can tie them to a warranty claim record
		
		Version		Date			Developer			Comment
				
		1.0			??/??/????		???? ????			Created
		1.1			13/09/2013		Martin Riverol		Only get parties for current VehiclePartyRoles (BUG #9416)
		1.2			27/04/2018		Chris Ledger		BUG 14664: CHANGE MostRecent CTE to improve performance

	*/
	
WITH MostRecent AS (
SELECT A.VehicleID, MAX(A.EventDate) AS EventDate
	FROM
	
	-- SELECT SALES EVENTS	-- V1.2 SPLIT SALES AND NON-SALES EVENTS TO IMPROVE PERFORMANCE
	(SELECT 
		WE.MatchedODSVehicleID AS VehicleID, 
		COALESCE(E.EventDate, R.RegistrationDate) AS EventDate
	FROM Warranty.WarrantyEvents WE
	INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE 
		/* added v1.1 */
		INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoles VPR ON VPRE.PartyID = VPR.PartyID
																AND VPRE.VehicleID = VPR.VehicleID
																AND VPR.ThroughDate IS NULL	
		/* added v1.1 */
	ON VPRE.VehicleID = WE.MatchedODSVehicleID
	INNER JOIN [$(SampleDB)].Event.Events E ON VPRE.EventID = E.EventID
	INNER JOIN [$(SampleDB)].Event.vwEventTypes ET ON E.EventTypeID = ET.EventTypeID
	LEFT JOIN [$(SampleDB)].Vehicle.VehicleRegistrationEvents VRE
		INNER JOIN [$(SampleDB)].Vehicle.Registrations R ON R.RegistrationID = VRE.RegistrationID
	ON VRE.VehicleID = VPRE.VehicleID
	AND COALESCE(R.ThroughDate, '31 December 9999') > CURRENT_TIMESTAMP
	WHERE ET.EventCategory = 'Sales'
	AND WE.DateTransferredToVWT IS NULL
	--AND WE.DateOfRepair >= DATEADD(DD,-100,GETDATE())		-- V1.2
	AND ISNULL(WE.MatchedODSVehicleID, 0) > 0
	AND ISNULL(WE.MatchedODSPersonID, 0) = 0 
	AND ISNULL(WE.MatchedODSOrganisationID, 0) = 0
	AND COALESCE(E.EventDate, R.RegistrationDate) <= WE.DateOfRepair
	
	UNION
	
	-- SELECT NON SALES EVENTS -- V1.2 SPLIT SALES AND NON-SALES EVENTS TO IMPROVE PERFORMANCE
	SELECT 
		WE.MatchedODSVehicleID AS VehicleID, 
		E.EventDate
	FROM Warranty.WarrantyEvents WE
	INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE 
		/* added v1.1 */
		INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoles VPR ON VPRE.PartyID = VPR.PartyID
																AND VPRE.VehicleID = VPR.VehicleID
																AND VPR.ThroughDate IS NULL	
		/* added v1.1 */
	ON VPRE.VehicleID = WE.MatchedODSVehicleID
	INNER JOIN [$(SampleDB)].Event.Events E ON VPRE.EventID = E.EventID
	INNER JOIN [$(SampleDB)].Event.vwEventTypes ET ON E.EventTypeID = ET.EventTypeID
	WHERE ET.EventCategory <> 'Sales'
	AND WE.DateTransferredToVWT IS NULL
	--AND WE.DateOfRepair >= DATEADD(DD,-100,GETDATE())		-- V1.2	
	AND ISNULL(WE.MatchedODSVehicleID, 0) > 0
	AND ISNULL(WE.MatchedODSPersonID, 0) = 0 
	AND ISNULL(WE.MatchedODSOrganisationID, 0) = 0
	AND E.EventDate <= WE.DateOfRepair
	) A
	GROUP BY A.VehicleID
),
Events AS (
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
SELECT 
	MR.VehicleID, 
	MR.EventDate, 	
	E.EventID, 
	PD.PartyID AS DriverPartyID, 
	RO.PartyID AS OwnerPartyID, 
	P.PartyID AS PurchaserPartyID, 
	OD.PartyID AS OtherDriverPartyID,
	COALESCE
	(
		PD.PartyID, 
		RO.PartyID, 
		P.PartyID, 
		OD.PartyID, 
		FM.PartyID
	) AS PartyID,
	ISNULL
	( 
		COALESCE
		(
			CASE
				WHEN PD.PartyID IS NOT NULL THEN 1 END, 
			RO.Person, 
			P.Person, 
			CASE WHEN OD.PartyID IS NOT NULL THEN 1 END, 
			FM.Person
		) , 0
	) AS Person, 
	ISNULL
	(
		COALESCE
		(
			CASE WHEN PD.PartyID IS NOT NULL THEN 0 END, 
			RO.Organisation, 
			P.Organisation, 
			CASE WHEN OD.PartyID IS NOT NULL THEN 0 END, 
			FM.Organisation
		), 0
	)AS Organisation
FROM MostRecent MR
INNER JOIN Events E ON E.VehicleID = MR.VehicleID
					AND E.EventDate = MR.EventDate
LEFT JOIN Warranty.vwPurchasers P ON P.VehicleID = E.VehicleID
								AND P.EventID = E.EventID
LEFT JOIN Warranty.vwRegisteredOwners RO ON RO.VehicleID = E.VehicleID
										AND RO.EventID = E.EventID
LEFT JOIN Warranty.vwPrincipalDrivers PD ON PD.VehicleID = E.VehicleID
										AND PD.EventID = E.EventID
LEFT JOIN Warranty.vwOtherDrivers OD ON OD.VehicleID = E.VehicleID
									AND OD.EventID = E.EventID
LEFT JOIN Warranty.vwFleetManagers FM ON FM.VehicleID = E.VehicleID
										AND FM.EventID = E.EventID