CREATE VIEW [Lookup].[vwCountries]
AS

SELECT CountryID, Country
FROM [$(SampleDB)].ContactMechanism.Countries