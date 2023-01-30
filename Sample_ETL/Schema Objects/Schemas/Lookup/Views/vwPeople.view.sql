CREATE VIEW Lookup.vwPeople

AS

SELECT DISTINCT
	PartyID,
	NameChecksum,
	LastName
FROM [$(SampleDB)].Party.People





