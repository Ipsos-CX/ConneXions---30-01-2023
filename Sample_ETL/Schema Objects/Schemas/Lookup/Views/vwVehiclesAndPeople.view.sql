CREATE VIEW Lookup.vwVehiclesAndPeople
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
	FROM [$(SampleDB)].Vehicle.VehiclePartyRoles
) VPR
INNER JOIN (
	SELECT DISTINCT 
		VehicleID, 
		VIN
	FROM [$(SampleDB)].Vehicle.Vehicles
) V ON VPR.VehicleID = V.VehicleID
INNER JOIN (
	SELECT DISTINCT 
		PartyID, 
		TitleID, 
		FirstName, 
		LastName, 
		SecondLastName,
		NameChecksum		
	FROM [$(SampleDB)].Party.People
) P ON VPR.PartyID = P.PartyID
