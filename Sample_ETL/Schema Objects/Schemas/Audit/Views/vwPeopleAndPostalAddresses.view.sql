/* -- CGR 14-06-2016 - Removed as part of BUG 11771 - This can be fully removed in the fullness of time	
					-- but for now I will leave in place but deactivated

CREATE VIEW Audit.vwPeopleAndPostalAddresses

AS

SELECT 
	P.PartyID,
	PPA.ContactMechanismID,
	P.NameChecksum,
	P2.Lastname
FROM Audit.vwPartyPostalAddresses PPA
INNER JOIN Audit.vwPeople P ON PPA.PartyID = P.PartyID
INNER JOIN [$(SampleDB)].Party.People P2 ON PPA.PartyID = P2.PartyID


*/