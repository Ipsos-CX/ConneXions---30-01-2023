CREATE VIEW Warranty.vwOtherDrivers

AS

WITH MostRecent AS (
	SELECT 
		VPRE.EventID, 
		VPRE.VehicleID, 
		VPRE.VehicleRoleTypeID, 
		MAX(VPRE.FromDate) AS FromDate
	FROM [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE		
	INNER JOIN [$(SampleDB)].Vehicle.VehicleRoleTypes VRT ON VRT.VehicleRoleTypeID = VPRE.VehicleRoleTypeID
	WHERE VRT.VehicleRoleType = 'Other Driver'
	GROUP BY VPRE.EventID, 
			VPRE.VehicleID, 
			VPRE.VehicleRoleTypeID
)
SELECT
	VPRE.VehicleID, 
	VPRE.PartyID, 
	VPRE.EventID, 
	VPRE.VehicleRoleTypeID
FROM [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE
INNER JOIN MostRecent MR ON MR.EventID = VPRE.EventID
						AND MR.VehicleID = VPRE.VehicleID
						AND MR.VehicleRoleTypeID = VPRE.VehicleRoleTypeID
						AND MR.FromDate = VPRE.FromDate
