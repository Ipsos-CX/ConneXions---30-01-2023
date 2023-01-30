CREATE VIEW Meta.vwBusinessEvents

AS

WITH Purchaser (VehicleRoleTypeID, EventID, PartyID) AS (
	SELECT	
		VPRE.VehicleRoleTypeID,
		VPRE.EventID,
		MAX(VPRE.PartyID) AS PartyID
	FROM Party.Organisations O
	JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.PartyID = O.PartyID
									AND VPRE.VehicleRoleTypeID = (SELECT VehicleRoleTypeID FROM Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Purchaser')
	JOIN Vehicle.VehiclePartyRoles VPR ON VPR.PartyID = O.PartyID	
									AND VPR.ThroughDate IS NULL
	GROUP BY VPRE.VehicleRoleTypeID, VPRE.EventID
),
RegisteredOwner (VehicleRoleTypeID, EventID, PartyID) AS (
	SELECT	
		VPRE.VehicleRoleTypeID,
		VPRE.EventID,
		MAX(VPRE.PartyID) AS PartyID
	FROM Party.Organisations O
	JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.PartyID = O.PartyID
									AND VPRE.VehicleRoleTypeID = (SELECT VehicleRoleTypeID FROM Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Registered Owner')
	JOIN Vehicle.VehiclePartyRoles VPR ON VPR.PartyID = O.PartyID	
									AND VPR.ThroughDate IS NULL
	GROUP BY VPRE.VehicleRoleTypeID, VPRE.EventID
),
PrincipleDriver (VehicleRoleTypeID, EventID, PartyID) AS (
	SELECT	
		VPRE.VehicleRoleTypeID,
		VPRE.EventID,
		MAX(VPRE.PartyID) AS PartyID
	FROM Party.Organisations O
	JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.PartyID = O.PartyID
									AND VPRE.VehicleRoleTypeID = (SELECT VehicleRoleTypeID FROM Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Principle Driver')
	JOIN Vehicle.VehiclePartyRoles VPR ON VPR.PartyID = O.PartyID	
									AND VPR.ThroughDate IS NULL
	GROUP BY VPRE.VehicleRoleTypeID, VPRE.EventID
),
OtherDriver (VehicleRoleTypeID, EventID, PartyID) AS (
	SELECT	
		VPRE.VehicleRoleTypeID,
		VPRE.EventID,
		MAX(VPRE.PartyID) AS PartyID
	FROM Party.Organisations O
	JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.PartyID = O.PartyID
									AND VPRE.VehicleRoleTypeID = (SELECT VehicleRoleTypeID FROM Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Other Driver')
	JOIN Vehicle.VehiclePartyRoles VPR ON VPR.PartyID = O.PartyID	
									AND VPR.ThroughDate IS NULL
	GROUP BY VPRE.VehicleRoleTypeID, VPRE.EventID
),
FleetManager (VehicleRoleTypeID, EventID, PartyID) AS (
	SELECT	
		VPRE.VehicleRoleTypeID,
		VPRE.EventID,
		MAX(VPRE.PartyID) AS PartyID
	FROM Party.Organisations O
	JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.PartyID = O.PartyID
									AND VPRE.VehicleRoleTypeID = (SELECT VehicleRoleTypeID FROM Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Fleet Manager')
	JOIN Vehicle.VehiclePartyRoles VPR ON VPR.PartyID = O.PartyID	
									AND VPR.ThroughDate IS NULL
	GROUP BY VPRE.VehicleRoleTypeID, VPRE.EventID
)
SELECT DISTINCT
	VPRE.EventID, 
	COALESCE(
		OP.VehicleRoleTypeID,  -- Purchaser
		ORO.VehicleRoleTypeID,  -- Registered Owner
		OPD.VehicleRoleTypeID,  --  Principle Driver
		OOD.VehicleRoleTypeID,  -- Other Driver
		OFM.VehicleRoleTypeID)  -- Fleet Manager
	AS VehicleRoleTypeID,
	COALESCE(
		OP.PartyID,  -- Purchaser
		ORO.PartyID,   -- Registered Owner
		OPD.PartyID,   --  Principle Driver
		OOD.PartyID,    -- Other Driver
		OFM.PartyID)  -- Fleet Manager
	AS PartyID,
	O.OrganisationName
FROM Vehicle.VehiclePartyRoleEvents VPRE
LEFT JOIN Purchaser OP ON VPRE.EventID = OP.EventID
LEFT JOIN RegisteredOwner ORO ON VPRE.EventID = ORO.EventID
LEFT JOIN PrincipleDriver OPD ON VPRE.EventID = OPD.EventID
LEFT JOIN OtherDriver OOD ON VPRE.EventID = OOD.EventID
LEFT JOIN FleetManager OFM ON VPRE.EventID = OFM.EventID
INNER JOIN Party.Organisations O ON O.PartyID = COALESCE(OP.PartyID, ORO.PartyID, OPD.PartyID, OOD.PartyID, OFM.PartyID)
WHERE COALESCE(OP.PartyID, ORO.PartyID, OPD.PartyID, OOD.PartyID, OFM.PartyID) IS NOT NULL


