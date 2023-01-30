CREATE VIEW [IAssistance].[vwFullLoadToVWT]

AS

SELECT DISTINCT 
	IE.IAssistanceID, 
	IE.AuditID, 
	IE.PhysicalRowID AS PhysicalFileRow, 
	IE.ManufacturerID, 
	IE.ManufacturerID as SampleSupplierPartyID, 
	(SELECT EventTypeID FROM [$(SampleDB)].Event.EventTypes WHERE EventType = 'I-Assistance') AS EventTypeID,
	IE.ManufacturerID as IAssistanceCentreOriginatorPartyID, 
	IE.[Address8(Country)] as IAssistanceCentreCode,
	IE.IAssistanceCallCloseDateOrig AS IAssistanceDateOrig, 
	IE.IAssistanceCallCloseDate AS IAssistanceDate,
	
	NULLIF(IE.CustomerUniqueID, '') AS CustomerUniqueID,
	
	CASE WHEN ISNULL(IE.CountryCode, '') = 'ZA' 
			AND NULLIF(IE.CustomerUniqueID, '') IS NOT NULL
		 THEN 1 ELSE 0 END AS CustIDUsable,
 	
 	CASE WHEN ISNULL(IE.CountryCode, '') = 'ZA' 
			AND NULLIF(IE.CustomerUniqueID, '') IS NOT NULL
		 THEN IE.ManufacturerID ELSE 0 END AS CustomerIdentifierOriginatorPartyID,

	IE.CompanyName, 
	IE.Title, 
	IE.FirstName, 
	IE.SurnameField1, 
	IE.SurnameField2,
	IE.Salutation, 
	IE.Address1,
	IE.Address2,
	IE.Address3,
	IE.Address4,
	IE.[Address5(City)],
	IE.[Address6(County)],
	IE.[Address7(Postcode/Zipcode)],
	IE.[Address8(Country)],
	IE.HomeTelephoneNumber, 
	IE.MobileTelephoneNumber, 
	IE.ModelName, 
	IE.ModelYear, 
	IE.VIN, 
	IE.RegistrationNumber, 
	
	IE.VehicleRegistrationDateOrig,
	
	IE.EmailAddress1,
	IE.EmailAddress2, 
	IE.PreferredLanguageID, 
	IE.CompleteSuppression, 
	IE.[Suppression-Email],
	IE.[Suppression-Phone],
	IE.[Suppression-Mail],
	IE.OwnershipCycle,
	IE.Gender, 
	IE.MonthAndYearOfBirth,
	IE.CountryID,
	IE.SampleTriggeredSelectionReqID
--SELECT * 	
FROM IAssistance.IAssistanceEvents IE
INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = IE.ManufacturerID
INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = IE.CountryID
WHERE (IE.PerformNormalVWTLoadFlag = 'Y')
AND ISNULL(IE.AuditID, 0) > 0
AND ISNULL(IE.PhysicalRowID, 0) > 0 
AND IE.DateTransferredToVWT IS NULL


