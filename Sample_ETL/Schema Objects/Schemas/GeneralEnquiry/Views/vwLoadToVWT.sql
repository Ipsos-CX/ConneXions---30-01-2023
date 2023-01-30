CREATE VIEW [GeneralEnquiry].[vwLoadToVWT]

AS

/*
	Purpose:	Transfers rows to VWT FROM GeneralEnquiryEvents that have not previously been transferred.
				Also populates the VIN with the appropriate GeneralEnquiry 'Unknown' vehicle WHERE VIN is blank.
	
	Version			Date			Developer			Comment
	1.0				2021-03-16		Chris Ledger		Created
	1.1				2021-07-07		Chris Ledger		Correct EventType
*/

SELECT DISTINCT 
	GE.GeneralEnquiryID, 
	GE.AuditID, 
	GE.PhysicalRowID AS PhysicalFileRow, 
	B.ManufacturerPartyID, 
	B.ManufacturerPartyID AS SampleSupplierPartyID, 
	(SELECT EventTypeID FROM [$(SampleDB)].Event.EventTypes WHERE EventType = 'CRC General Enquiry') AS EventTypeID,	-- V1.1
	B.ManufacturerPartyID AS CRCCentreOriginatorPartyID, 
	GE.CRCCentreCode,
	GE.GeneralEnquiryDateOrig, 
	GE.GeneralEnquiryDate,
	NULLIF(GE.UniqueCustomerID, '') AS UniqueCustomerID,	
	CASE	WHEN ISNULL(GE.MarketCode, '') = 'ZAF' AND NULLIF(GE.UniqueCustomerID, '') IS NOT NULL THEN 1 
			ELSE 0 END AS CustIDUsable, 	
 	CASE	WHEN ISNULL(GE.MarketCode, '') = 'ZAF' AND NULLIF(GE.UniqueCustomerID, '') IS NOT NULL THEN B.ManufacturerPartyID 
			ELSE 0 END AS CustomerIdentifierOriginatorPartyID,
	GE.CompanyName, 
	GE.CustomerTitle, 
	GE.CustomerFirstname, 
	GE.CustomerLastName, 
	GE.AddressLine1,
	GE.AddressLine2,
	GE.AddressLine3,
	GE.AddressLine4,
	GE.City,
	GE.County,
	GE.Country,
	GE.PostalCode,
	GE.PhoneHome, 
	GE.PhoneMobile, 
	GE.VehicleModel, 
	GE.VIN, 
	GE.VehicleRegNumber,
	GE.EmailAddress,
	GE.PreferredLanguageID, 
	'' AS Gender, 
	C.CountryID,
	GE.SampleTriggeredSelectionReqID,
	GE.COMPLETE_SUPPRESSION,
	GE.SUPPRESSION_EMAIL,
	GE.SUPPRESSION_PHONE,
	GE.SUPPRESSION_MAIL
--SELECT B.*, * 	
FROM GeneralEnquiry.GeneralEnquiryEvents GE
	INNER JOIN [$(SampleDB)].dbo.Brands B ON SUBSTRING(B.Brand, 1, 1) = SUBSTRING(LTRIM(GE.BrandCode), 1, 1)
	INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.ISOAlpha3 = GE.MarketCode
	LEFT JOIN dbo.VWT VWT ON GE.AuditID = VWT.AuditID 
							AND GE.PhysicalRowID = VWT.PhysicalFileRow
WHERE ISNULL(GE.AuditID, 0) > 0
	AND ISNULL(GE.PhysicalRowID, 0) > 0 
	AND VWT.AuditID IS NULL
	AND GE.DateTransferredToVWT IS NULL



