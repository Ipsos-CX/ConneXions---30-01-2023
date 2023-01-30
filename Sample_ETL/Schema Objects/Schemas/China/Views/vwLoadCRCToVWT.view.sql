CREATE VIEW [China].[vwLoadCRCToVWT]

AS

SELECT DISTINCT 
	WE.ID, 
	WE.AuditID, 
	WE.PhysicalRowID AS PhysicalFileRow, 
	WE.ManufacturerPartyID AS ManufacturerID, 
	WE.ManufacturerPartyID as SampleSupplierPartyID, 
	(SELECT EventTypeID FROM [$(SampleDB)].Event.EventTypes WHERE EventType = 'CRC') AS EventTypeID,
	WE.ManufacturerPartyID as CRCCentreOriginatorPartyID, 
	WE.CRCCode as CRCCentreCode,
	We.EventDate AS CRCDateOrig, 
	We.ConvertedEventDate AS CRCDate,
	
	NULLIF(WE.CustomerUniqueId, '') AS UniqueCustomerId,
	
	CASE WHEN ISNULL(WE.MarketCode, '') = 'ZAF' 
			AND NULLIF(WE.CustomerUniqueId, '') IS NOT NULL
		 THEN 1 ELSE 0 END AS CustIDUsable,
 	
 	CASE WHEN ISNULL(WE.MarketCode, '') = 'ZAF' 
			AND NULLIF(WE.CustomerUniqueId, '') IS NOT NULL
		 THEN B.ManufacturerPartyID ELSE 0 END AS CustomerIdentifierOriginatorPartyID,

	WE.CoName As CompanyName, 
	WE.Title As CustomerTitle, 
	'' AS CustomerFirstname, 
	WE.Surname As CustomerLastName, 
	WE.add1 As AddressLine1,
	WE.add2 As AddressLine2,
	WE.add3 As AddressLine3,
	WE.add4 As AddressLine4,
	WE.add5 As AddressLine5,
	WE.add6 As AddressLine6,
	WE.add7 As AddressLine7,
	WE.add8 As AddressLine8,
	WE.add9 As AddressLine9,
	WE.Tel_1 As PhoneHome, 
	WE.Tel_1 As PhoneMobile, 
	WE.Model As VehicleModel, 
	WE.VIN, 
	WE.Carreg As VehicleRegNumber,
	
	WE.EmailAddress,
	WE.languageID AS PreferredLanguageID, 
	'' AS Gender, 
	WE.CountryID,
	WE.SampleTriggeredSelectionReqID
FROM	[China].[CRC_WithResponses] WE
INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = WE.ManufacturerPartyID
INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = WE.CountryID
WHERE	ISNULL(WE.AuditID, 0) > 0 AND 
		ISNULL(WE.PhysicalRowID, 0) > 0 AND 
		WE.DateTransferredToVWT IS NULL