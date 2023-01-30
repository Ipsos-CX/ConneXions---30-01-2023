/* -- CGR 14-06-2016 - Removed as part of BUG 11771 - This can be fully removed in the fullness of time	
					-- but for now I will leave in place but deactivated


CREATE VIEW [Audit].[vwVehiclesAndOrganisations]
AS

SELECT
	V.VehicleID, 
	O.PartyID AS MatchedOrganisationID, 
	O.OrganisationName, 
	V.VIN,
	CHECKSUM(V.VIN) AS VehicleChecksum, 
	O.OrganisationNameChecksum
FROM (
	SELECT DISTINCT 
		PartyID, 
		VehicleID
	FROM [$(AuditDB)].Audit.VehiclePartyRoles
) VPR
INNER JOIN (
	SELECT DISTINCT 
		vehicleid, 
		vin
	FROM [$(AuditDB)].Audit.Vehicles
) V ON VPR.VehicleID = V.VehicleID
INNER JOIN (
	SELECT DISTINCT 
		PartyID, 
		OrganisationName,
		OrganisationNameChecksum
	FROM [$(AuditDB)].Audit.Organisations
) O ON VPR.PartyID = O.PartyID

*/