CREATE VIEW Meta.vwVehiclePartyRoleEvents

AS

SELECT	
	VPRE.EventID, 
	VPRE.VehicleID, 
	MAX(P.Purchaser) Purchaser, 
	MAX(RO.RegisteredOwner) RegisteredOwner, 
	MAX(PD.PrincipleDriver) PrincipleDriver, 
	MAX(OD.OtherDriver) OtherDriver,
	MAX(FM.FleetManager) FleetManager
FROM Vehicle.VehiclePartyRoleEvents VPRE 
INNER JOIN Vehicle.VehiclePartyRoles VPR ON VPR.PartyID = VPRE.PartyID 
					AND VPR.VehicleRoleTypeID = VPRE.VehicleRoleTypeID 
					AND VPR.VehicleID = VPRE.VehicleID 
					AND COALESCE(VPR.ThroughDate, '31 December 9999') > Current_TimeStamp
LEFT JOIN (
	SELECT 
		PartyID AS Purchaser, 
		VehicleID, 
		EventID
	FROM Vehicle.VehiclePartyRoleEvents
	WHERE VehicleRoleTypeID = (SELECT VehicleRoleTypeID FROM Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Purchaser')
) P ON P.VehicleID = VPRE.VehicleID 
AND P.EventID = VPRE.EventID 
AND VPRE.VehicleRoleTypeID = (SELECT VehicleRoleTypeID FROM Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Purchaser')
LEFT JOIN (
	SELECT	
		PartyID AS RegisteredOwner, 
		VehicleID, 
		EventID
	FROM Vehicle.VehiclePartyRoleEvents
	WHERE VehicleRoleTypeID = (SELECT VehicleRoleTypeID FROM Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Registered Owner')
) RO ON RO.VehicleID = VPRE.VehicleID 
AND RO.EventID = VPRE.EventID 
AND VPRE.VehicleRoleTypeID = (SELECT VehicleRoleTypeID FROM Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Registered Owner')
LEFT JOIN (
	SELECT	
		PartyID AS PrincipleDriver, 
		VehicleID, 
		EventID
	FROM Vehicle.VehiclePartyRoleEvents
	WHERE VehicleRoleTypeID = (SELECT VehicleRoleTypeID FROM Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Principle Driver')
) PD ON PD.VehicleID = VPRE.VehicleID 
AND PD.EventID = VPRE.EventID 
AND VPRE.VehicleRoleTypeID = (SELECT VehicleRoleTypeID FROM Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Principle Driver')
LEFT JOIN (
	SELECT	
		PartyID AS OtherDriver, 
		VehicleID, 
		EventID
	FROM Vehicle.VehiclePartyRoleEvents
	WHERE VehicleRoleTypeID = (SELECT VehicleRoleTypeID FROM Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Other Driver')
) OD ON OD.VehicleID = VPRE.VehicleID 
AND OD.EventID = VPRE.EventID 
AND VPRE.VehicleRoleTypeID = (SELECT VehicleRoleTypeID FROM Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Other Driver')
LEFT JOIN (
	SELECT	
		PartyID AS FleetManager, 
		VehicleID, 
		EventID
	FROM Vehicle.VehiclePartyRoleEvents
	WHERE VehicleRoleTypeID = (SELECT VehicleRoleTypeID FROM Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Fleet Manager')
) FM ON FM.VehicleID = VPRE.VehicleID 
AND FM.EventID = VPRE.EventID 
AND VPRE.VehicleRoleTypeID = (SELECT VehicleRoleTypeID FROM Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Fleet Manager')
GROUP BY
	VPRE.EventID, 
	VPRE.VehicleID






