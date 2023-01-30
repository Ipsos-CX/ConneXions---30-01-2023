CREATE VIEW Load.vwPostalAddresses

AS

SELECT 
	AuditItemID, 
	AddressParentAuditItemID, 
	MatchedODSAddressID AS ContactMechanismID,
	(SELECT ContactMechanismTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Postal Address') AS ContactMechanismTypeID,
	ISNULL(BuildingName, '') AS BuildingName, 
	ISNULL(SubStreetAndNumberOrig, '') AS SubStreetAndNumberOrig, 
	ISNULL(SubStreetOrig, '') AS SubStreetOrig, 
	ISNULL(SubStreetNumber, '') AS SubStreetNumber, 
	ISNULL(SubStreet, '') AS SubStreet, 
	ISNULL(StreetAndNumberOrig, '') AS StreetAndNumberOrig, 
	ISNULL(StreetOrig, '') AS StreetOrig, 
	ISNULL(StreetNumber, '') AS StreetNumber, 
	ISNULL(Street, '') AS Street, 
	ISNULL(SubLocality, '') AS SubLocality, 
	ISNULL(Locality, '') AS Locality, 
	ISNULL(Town, '') AS Town, 
	ISNULL(Region, '') AS Region, 
	ISNULL(PostCode, '') AS PostCode, 
	CountryID, 
	dbo.udfGenerateAddressChecksum(
		BuildingName,
		SubStreetNumber,
		SubStreet,
		StreetNumber,
		Street,
		SubLocality,
		Locality,
		Town,
		Region,
		PostCode,
		CountryID
	) AS AddressChecksum
FROM dbo.VWT
WHERE  	dbo.udfGenerateAddressChecksum(
		BuildingName,
		SubStreetNumber,
		SubStreet,
		StreetNumber,
		Street,
		SubLocality,
		Locality,
		Town,
		Region,
		PostCode,
		CountryID ) <> 0

