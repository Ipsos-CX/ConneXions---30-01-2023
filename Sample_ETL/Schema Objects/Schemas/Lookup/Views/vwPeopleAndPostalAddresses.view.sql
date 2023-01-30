CREATE VIEW Lookup.vwPeopleAndPostalAddresses

AS

SELECT 
	P.PartyID,
	PPA.ContactMechanismID,
	P.NameChecksum,
	P.Lastname
FROM Lookup.vwPartyPostalAddresses PPA
INNER JOIN Lookup.vwPeople P ON PPA.PartyID = P.PartyID
