CREATE VIEW ContactMechanism.vwPostalAddresses

AS

SELECT
	 PA.ContactMechanismID
	,PA.BuildingName
	,CASE
		WHEN PA.CountryID IN (SELECT CountryID FROM ContactMechanism.Countries WHERE ISOAlpha3 IN ('GBR', 'USA', 'CAN'))
			THEN LTRIM(RTRIM(PA.SubStreetNumber + ' ' + PA.SubStreet))
		ELSE LTRIM(RTRIM(PA.SubStreet + ' ' + PA.SubStreetNumber))
	END AS SubStreet
	,CASE
		WHEN PA.CountryID IN (SELECT CountryID FROM ContactMechanism.Countries WHERE ISOAlpha3 IN ('GBR', 'USA', 'CAN'))
			THEN LTRIM(RTRIM(PA.StreetNumber + ' ' + PA.Street))
		ELSE LTRIM(RTRIM(PA.Street + ' ' + PA.StreetNumber))
	END AS Street
	,LTRIM(RTRIM(PA.SubLocality)) AS SubLocality
	,LTRIM(RTRIM(PA.Locality)) AS Locality
	,LTRIM(RTRIM(PA.Town)) AS Town
	,LTRIM(RTRIM(PA.Region)) AS Region
	,LTRIM(RTRIM(PA.PostCode)) AS PostCode
	,PA.CountryID
	,C.Country
	,C.ISOAlpha2
	,C.ISOAlpha3
	,C.NumericCode
	,C.DefaultLanguageID
	,CMT.ContactMechanismType
FROM ContactMechanism.PostalAddresses PA
INNER JOIN ContactMechanism.Countries C ON C.CountryID = PA.CountryID
INNER JOIN ContactMechanism.ContactMechanisms CM ON CM.ContactMechanismID = PA.ContactMechanismID
INNER JOIN ContactMechanism.ContactMechanismTypes CMT ON CMT.ContactMechanismTypeID = CM.ContactMechanismTypeID