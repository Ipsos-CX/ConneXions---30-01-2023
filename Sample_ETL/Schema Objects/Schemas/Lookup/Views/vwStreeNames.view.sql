CREATE VIEW Lookup.vwStreetNames
AS

SELECT
	 SN.CountryID
	,SN.StreetName AS Standard
	,SNV.StreetNameVariance AS Variance
FROM Lookup.StreetNames SN
INNER JOIN Lookup.StreetNameVariances SNV ON SN.StreetNameID = SNV.StreetNameID




