CREATE VIEW [Lookup].[vwVehiclesAndOrganisations]
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
	FROM [$(SampleDB)].Vehicle.VehiclePartyRoles
) VPR
INNER JOIN (
	SELECT DISTINCT 
		vehicleid, 
		vin
	FROM [$(SampleDB)].Vehicle.Vehicles
) V ON VPR.VehicleID = V.VehicleID
INNER JOIN (
	SELECT DISTINCT 
		PartyID, 
		OrganisationName,
		OrganisationNameChecksum
	FROM [$(SampleDB)].Party.Organisations
) O ON VPR.PartyID = O.PartyID


