CREATE VIEW ContactMechanism.vwDA_PostalAddresses

AS

SELECT
	CONVERT(BIGINT, 0) AS AuditItemID, 
	CONVERT(BIGINT, 0) AS AddressParentAuditItemID, 
	ContactMechanismID, 
	(SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Postal Address') AS ContactMechanismTypeID, 
	BuildingName, 
	CONVERT(NVARCHAR(400), '') AS SubStreetAndNumberOrig, 
	CONVERT(NVARCHAR(400), '') AS SubStreetOrig, 
	SubStreetNumber, 
	SubStreet, 
	CONVERT(NVARCHAR(400), '') AS StreetAndNumberOrig, 
	CONVERT(NVARCHAR(400), '') AS StreetOrig, 
	StreetNumber, 
	Street, 
	SubLocality, 
	Locality, 
	Town, 
	Region, 
	PostCode, 
	CountryID, 
	AddressChecksum	
FROM ContactMechanism.PostalAddresses














