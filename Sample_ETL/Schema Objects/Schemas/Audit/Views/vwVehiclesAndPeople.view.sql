/* -- CGR 14-06-2016 - Removed as part of BUG 11771 - This can be fully removed in the fullness of time	
					-- but for now I will leave in place but deactivated


CREATE VIEW Audit.vwVehiclesAndPeople
AS



SELECT 
	V.VehicleID, 
	P.PartyID AS MatchedPersonID, 
	V.VIN,
	CHECKSUM(V.VIN) AS VehicleChecksum, 
	P.NameChecksum,
	P.LastName
FROM (
	SELECT DISTINCT 
		PartyID, 
		VehicleID
	FROM [$(AuditDB)].[Audit].VehiclePartyRoles
) VPR
INNER JOIN (
	SELECT DISTINCT 
		VehicleID, 
		VIN
	FROM [$(AuditDB)].[Audit].Vehicles
) V ON VPR.VehicleID = V.VehicleID
INNER JOIN (
	SELECT DISTINCT 
		PartyID, 
		TitleID, 
		FirstName, 
		LastName, 
		SecondLastName,
		NameChecksum		
	FROM [$(AuditDB)].Audit.People
) P ON VPR.PartyID = P.PartyID

*/