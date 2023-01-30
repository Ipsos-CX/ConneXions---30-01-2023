CREATE VIEW Load.vwVehiclePartyRoles

AS

	SELECT	
		AuditItemID, 
		MatchedODSPersonID AS PartyID,
		(SELECT VehicleRoleTypeID FROM [$(SampleDB)].Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Principle Driver') AS VehicleRoleTypeID,
		MatchedODSVehicleID AS VehicleID,
		CURRENT_TIMESTAMP AS FromDate
	FROM dbo.VWT
	WHERE ISNULL(MatchedODSPersonID, 0) > 0 
	AND ISNULL(MatchedODSOrganisationID, 0) = 0
	AND MatchedODSVehicleID > 0
	AND ISNULL(DriverIndicator, 0) = 0 -- EXCLUDE CUPID DATA
	AND ISNULL(OwnerIndicator, 0) = 0 -- EXCLUDE CUPID DATA
	AND ISNULL(ManagerIndicator, 0) = 0 -- EXCLUDE CUPID DATA

UNION

	SELECT	
		AuditItemID, 
		COALESCE(NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSPartyID, 0), 0) AS PartyID,
		CASE
			WHEN ISNULL(MatchedODSPersonID, 0) > 0 AND ISNULL(MatchedODSOrganisationID, 0) = 0 THEN (SELECT VehicleRoleTypeID FROM [$(SampleDB)].Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Registered Owner')
			WHEN ISNULL(MatchedODSPersonID, 0) > 0 AND ISNULL(MatchedODSOrganisationID, 0) > 0 THEN (SELECT VehicleRoleTypeID FROM [$(SampleDB)].Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Principle Driver')
			ELSE (SELECT VehicleRoleTypeID FROM [$(SampleDB)].Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Other Driver')
		END AS VehicleRoleTypeID,
		MatchedODSVehicleID AS VehicleID,
		CURRENT_TIMESTAMP AS FromDate
	FROM dbo.VWT
	WHERE COALESCE(NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSPartyID, 0)) > 0
	AND MatchedODSVehicleID > 0
	AND ISNULL(DriverIndicator, 0) = 0 -- EXCLUDE CUPID DATA
	AND ISNULL(OwnerIndicator, 0) = 0 -- EXCLUDE CUPID DATA
	AND ISNULL(ManagerIndicator, 0) = 0 -- EXCLUDE CUPID DATA
		
UNION

	SELECT	
		AuditItemID, 
		MatchedODSOrganisationID AS PartyID,
		(SELECT VehicleRoleTypeID FROM [$(SampleDB)].Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Registered Owner') AS VehicleRoleTypeID,
		MatchedODSVehicleID AS VehicleID,
		CURRENT_TIMESTAMP AS FromDate
	FROM dbo.VWT
	WHERE ISNULL(MatchedODSOrganisationID, 0) > 0
	AND MatchedODSVehicleID > 0
	AND ISNULL(DriverIndicator, 0) = 0 -- EXCLUDE CUPID DATA
	AND ISNULL(OwnerIndicator, 0) = 0 -- EXCLUDE CUPID DATA
	AND ISNULL(ManagerIndicator, 0) = 0 -- EXCLUDE CUPID DATA
	
UNION

	-- CUPID DATA

	SELECT  
		AuditItemID, 
		COALESCE(NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSOrganisationID, 0), NULLIF(MatchedODSPartyID, 0), 0) AS PartyID,
		(SELECT VehicleRoleTypeID FROM [$(SampleDB)].Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Principle Driver') AS VehicleRoleTypeID,
		MatchedODSVehicleID AS VehicleID,
		CURRENT_TIMESTAMP AS FromDate
	FROM dbo.VWT
	WHERE DriverIndicator = 1
	AND MatchedODSVehicleID > 0

UNION

	SELECT  
		AuditItemID, 
		COALESCE(NULLIF(MatchedODSOrganisationID, 0), NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSPartyID, 0), 0) AS PartyID,
		(SELECT VehicleRoleTypeID FROM [$(SampleDB)].Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Registered Owner') AS VehicleRoleTypeID,
		MatchedODSVehicleID AS VehicleID,
		CURRENT_TIMESTAMP AS FromDate
	FROM dbo.VWT
	WHERE OwnerIndicator = 1
	AND MatchedODSVehicleID > 0

UNION

	SELECT  
		AuditItemID, 
		COALESCE(NULLIF(MatchedODSOrganisationID, 0), NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSPartyID, 0), 0) AS PartyID,
		(SELECT VehicleRoleTypeID FROM [$(SampleDB)].Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Fleet Manager') AS VehicleRoleTypeID,
		MatchedODSVehicleID AS VehicleID,
		CURRENT_TIMESTAMP AS FromDate
	FROM dbo.VWT
	WHERE ManagerIndicator = 1
	AND MatchedODSVehicleID > 0








