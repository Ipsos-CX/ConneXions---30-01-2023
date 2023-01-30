CREATE VIEW [China].[vwLoadSalesToVWT]

AS
SELECT DISTINCT

		SWR.ID,
		SWR.AuditID,
		SWR.PhysicalRowID AS PhysicalFileRow, 
		SWR.CompanyName AS OrganisationName,
		SWR.CompanyName AS OrganisationNameOrig,
		SWR.VehicleDeliveryDate,
		SWR.ConvertedVehicleDeliveryDate,
		SWR.VehiclePurchaseDate AS SaleDateOrig,
		SWR.ConvertedVehiclePurchaseDate AS SaleDate,
		SWR.VehicleRegistrationDate AS RegistrationDateOrig,
		SWR.ConvertedVehicleRegistrationDate AS RegistrationDate,
		SWR.Title,
		'' AS FirstName,
		'' AS FirstNameOrig,
		LTRIM(ISNULL(SWR.FirstName , '') + ' ' + ISNULL(SWR.SurnameField1, '')) AS LastName,
		LTRIM(ISNULL(SWR.FirstName , '') + ' ' + ISNULL(SWR.SurnameField1, '')) AS LastNameOrig,
		SWR.SurnameField2 AS SecondLastName,
		SWR.SurnameField2 AS SecondLastNameOrig,
		SWR.Salutation,
		SWR.Address1 AS Street,
		SWR.Address2 AS Locality,
		SWR.Address5 AS Town,
		SWR.Address6 AS Region,
		SWR.Address7 AS Postcode,
		SWR.Address8 AS Country,
		SWR.HomeTelephoneNumber AS PrivTel,
		SWR.BusinessTelephoneNumber AS BusTel,
		SWR.MobileTelephoneNumber AS MobileTel,
		SWR.ModelName AS ModelDescription,
		SWR.ModelYear AS BuildYear,
		SWR.VIN AS VehicleIdentificationNumber,
		CASE 
			WHEN LEN(ISNULL(SWR.VIN,'')) = 17 THEN CAST (1  AS bit)
				ELSE CAST (0  AS bit)
		END AS VehicleIdentificationNumberUsable,
		SWR.RegistrationNumber  AS VehicleRegistrationNumber,
		ISNULL(SWR.EmailAddress1,'') AS EmailAddress,
		ISNULL(SWR.EmailAddress2,'') AS PrivEmailAddress,
		CASE LEFT (SWR.CompleteSuppression,1)
				WHEN 'Y' THEN CAST (1  AS bit)
				ELSE CAST (0  AS bit)
		END AS PartySuppression,
		CASE LEFT (SWR.SuppressionEmail,1)
			WHEN 'Y' THEN CAST (1  AS bit)
			ELSE CAST (0  AS bit)
		END AS EmailSuppression,
		CASE LEFT (SWR.SuppressionMail,1)
			WHEN 'Y' THEN CAST (1  AS bit)
			ELSE CAST (0  AS bit)
		END AS PostalSuppression,
		SWR.InvoiceNumber,
		SWR.InvoiceValue,
		SWR.ServiceEmployeeCode AS SalesmanCode,
		SWR.EmployeeName AS Salesman,
		CASE 
			 WHEN SWR.OwnershipCycle = '' THEN 0
			 WHEN SWR.OwnershipCycle IS NULL THEN 0
			 WHEN ISNUMERIC(SWR.OwnershipCycle) = 1 THEN CAST (SWR.OwnershipCycle AS Int)
			 ELSE 0
		END AS OwnershipCycle,
		CASE LEFT (SWR.Gender,1)
			WHEN 'M' THEN CAST (1  AS Int)
			WHEN 'F' THEN CAST (2  AS Int)
			ELSE CAST (0  AS Int)
		END AS GenderID,
		SWR.PrivateOwner,
		SWR.OwningCompany,
		SWR.UserChooserDriver,
		SWR.EmployerCompany,
		SWR.PermissionsForContact,
		SWR.ManufacturerPartyID AS ManufacturerID,
		SWR.SampleSupplierPartyID,
		SWR.CountryID,
		SWR.EventTypeID AS ODSEventTypeID,
		SWR.EventType AS JLRSuppliedEventType,
		SWR.LanguageID,
		SWR.SetNameCapitalisation,
		SWR.SampleTriggeredSelectionReqID,
		NULLIF(SWR.CustomerIdentifier,'') AS CustomerIdentifier, 
		SWR.CustomerIdentifierUsable,
		SWR.DealerCode AS SalesDealerCode,
		SWR.DealerCodeOriginatorPartyID AS SalesDealerCodeOriginatorPartyID

FROM [China].[Sales_WithResponses] SWR
INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = SWR.ManufacturerPartyID

WHERE ISNULL(SWR.AuditID, 0) > 0
		AND ISNULL(SWR.PhysicalRowID, 0) > 0 
		AND SWR.DateTransferredToVWT IS NULL