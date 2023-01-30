CREATE VIEW [CRC].[vwLoadToVWT]

AS

SELECT DISTINCT 
	WE.CRC_ID, 
	WE.AuditID, 
	WE.PhysicalRowID AS PhysicalFileRow, 
	B.ManufacturerPartyID, 
	B.ManufacturerPartyID as SampleSupplierPartyID, 
	(SELECT EventTypeID FROM [$(SampleDB)].Event.EventTypes WHERE EventType = 'CRC') AS EventTypeID,
	B.ManufacturerPartyID as CRCCentreOriginatorPartyID, 
	WE.CRCCode as CRCCentreCode,
	We.SRClosedDate AS CRCDateOrig, 
	We.ConvertedSRClosedDate AS CRCDate,
	
	NULLIF(WE.UniqueCustomerId, '') AS UniqueCustomerId,
	
	CASE WHEN ISNULL(WE.MarketCode, '') = 'ZAF' 
			AND NULLIF(WE.UniqueCustomerId, '') IS NOT NULL
		 THEN 1 ELSE 0 END AS CustIDUsable,
 	
 	CASE WHEN ISNULL(WE.MarketCode, '') = 'ZAF' 
			AND NULLIF(WE.UniqueCustomerId, '') IS NOT NULL
		 THEN B.ManufacturerPartyID ELSE 0 END AS CustomerIdentifierOriginatorPartyID,

	WE.CompanyName, 
	WE.CustomerTitle, 
	WE.CustomerFirstname, 
	WE.CustomerLastName, 
	WE.AddressLine1,
	WE.AddressLine2,
	WE.AddressLine3,
	WE.AddressLine4,
	WE.City,
	WE.County,
	WE.Country,
	WE.PostalCode,
	WE.PhoneHome, 
	WE.PhoneMobile, 
	WE.VehicleModel, 
	WE.VIN, 
	WE.VehicleRegNumber,
	
	WE.EmailAddress,
	WE.PreferredLanguageID, 
	'' AS Gender, 
	C.CountryID,
	WE.SampleTriggeredSelectionReqID,
	WE.COMPLETE_SUPPRESSION,		-- 2018-06-04
	WE.SUPPRESSION_EMAIL,			-- 2018-06-04
	WE.SUPPRESSION_PHONE,			-- 2018-06-04
	WE.SUPPRESSION_MAIL				-- 2018-06-04
--SELECT B.*, * 	
FROM CRC.CRCEvents WE
INNER JOIN [$(SampleDB)].dbo.Brands B ON SUBSTRING(B.Brand, 1, 1) = SUBSTRING(LTRIM(WE.BrandCode), 1, 1)
INNER JOIN [$(SampleDB)].ContactMechanism.Countries c ON c.ISOAlpha3 = WE.MarketCode
LEFT JOIN dbo.VWT VWT ON WE.AuditID = VWT.AuditID AND WE.PhysicalRowID = VWT.PhysicalFileRow
WHERE ISNULL(WE.AuditID, 0) > 0
AND ISNULL(WE.PhysicalRowID, 0) > 0 
AND VWT.AuditID IS NULL
AND WE.DateTransferredToVWT IS NULL



