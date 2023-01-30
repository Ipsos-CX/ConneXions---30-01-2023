CREATE VIEW [China].[vwFullRoadsideLoadToVWT]
	
AS 
	
SELECT DISTINCT 
				WE.ID, 
				WE.AuditID, 
				WE.PhysicalRowID AS PhysicalFileRow, 
				WE.ManufacturerPartyID AS ManufacturerID, 
				WE.ManufacturerPartyID as SampleSupplierPartyID, 
				(SELECT EventTypeID FROM [$(SampleDB)].Event.EventTypes WHERE EventType = 'Roadside') AS EventTypeID,
				WE.ManufacturerPartyID as RoadsideNetworkOriginatorPartyID, 
				WE.Address8 as RoadsideNetworkCode,
				COALESCE(WE.BreakdownDate, WE.CarHireStartDate) AS RoadsideDateOrig, 
				COALESCE(WE.BreakdownDate, WE.CarHireStartDate) AS RoadsideDate,
				NULLIF(WE.CustomerUniqueId, '') AS CustomerUniqueId,
				1 AS CustIDUsable,
				WE.ManufacturerPartyID AS CustomerIdentifierOriginatorPartyID,
				WE.CompanyName, 
				WE.Title, 
				WE.Firstname, 
				WE.SurnameField1, 
				WE.SurnameField2,
				WE.Salutation, 
				WE.Address1,
				WE.Address2,
				WE.Address3,
				WE.Address4,
				WE.Address5,
				WE.Address6,
				WE.Address7,
				WE.Address8,
				WE.HomeTelephoneNumber, 
				WE.MobileTelephoneNumber, 
				WE.ModelName, 
				WE.ModelYear, 
				WE.VIN, 
				WE.RegistrationNumber, 
	
				WE.VehicleRegistrationDate AS VehicleRegistrationDateOrig,
	
				WE.EmailAddress1,
				WE.EmailAddress2, 
				WE.LanguageID, 
				WE.CompleteSuppression, 
				WE.SuppressionEmail,
				WE.SuppressionPhone,
				WE.SuppressionMail,
				WE.OwnershipCycle,
				WE.Gender, 
				WE.MonthAndYearOfBirth,
				WE.CountryID,
				WE.BreakdownCountryID,
	WE.SampleTriggeredSelectionReqID
--select * 	
FROM	[China].[Roadside_WithResponses] WE
INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = WE.ManufacturerPartyID
INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = WE.CountryID
WHERE	ISNULL(WE.AuditID, 0) > 0 AND 
		ISNULL(WE.PhysicalRowID, 0) > 0 AND 
		WE.DateTransferredToVWT IS NULL;