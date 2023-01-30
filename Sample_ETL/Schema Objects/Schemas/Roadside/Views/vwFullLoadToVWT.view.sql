CREATE VIEW [Roadside].[vwFullLoadToVWT]

AS

SELECT DISTINCT 
	WE.RoadsideID, 
	WE.AuditID, 
	WE.PhysicalRowID AS PhysicalFileRow, 
	WE.ManufacturerID, 
	WE.ManufacturerID as SampleSupplierPartyID, 
	(SELECT EventTypeID FROM [$(SampleDB)].Event.EventTypes WHERE EventType = 'Roadside') AS EventTypeID,
	WE.ManufacturerID as RoadsideNetworkOriginatorPartyID, 
	WE.[Address8(Country)] as RoadsideNetworkCode,
	COALESCE(WE.BreakdownDateOrig, WE.CarHireStartDateOrig) AS RoadsideDateOrig, 
	COALESCE(WE.BreakdownDate, WE.CarHireStartDate) AS RoadsideDate,
	
	NULLIF(WE.CustomerUniqueId, '') AS CustomerUniqueId,
	
	CASE WHEN ISNULL(WE.CountryCode, '') = 'ZA' 
			AND NULLIF(WE.CustomerUniqueId, '') IS NOT NULL
		 THEN 1 ELSE 0 END AS CustIDUsable,
 	
 	CASE WHEN ISNULL(WE.CountryCode, '') = 'ZA' 
			AND NULLIF(WE.CustomerUniqueId, '') IS NOT NULL
		 THEN WE.ManufacturerID ELSE 0 END AS CustomerIdentifierOriginatorPartyID,

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
	WE.[Address5(city)],
	WE.[Address6(County)],
	WE.[Address7(Postcode/Zipcode)],
	WE.[Address8(Country)],
	WE.HomeTelephoneNumber, 
	WE.MobileTelephoneNumber, 
	WE.ModelName, 
	WE.ModelYear, 
	WE.VIN, 
	WE.RegistrationNumber, 
	
	WE.VehicleRegistrationDateOrig,
	
	WE.EmailAddress1,
	WE.EmailAddress2, 
	WE.PreferredLanguageID, 
	WE.CompleteSuppression, 
	WE.[Suppression-Email],
	WE.[Suppression-Phone],
	WE.[Suppression-Mail],
	WE.OwnershipCycle,
	WE.Gender, 
	WE.MonthAndYearOfBirth,
	WE.CountryID,
	WE.BreakdownCountryID,
	WE.SampleTriggeredSelectionReqID
--select * 	
FROM Roadside.RoadsideEvents WE
INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = WE.ManufacturerID
INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = WE.CountryID
WHERE (		PerformNormalVWTLoadFlag = 'Y'
		OR (		PerformNormalVWTLoadFlag = 'N'				--BUG 12659 -- Force a normal VWT load where an Email + Name(/Org Name) is present on the row 
				AND ISNULL(M.AltRoadsideEmailMatching, 0) = 1				-- and the Market table AltRoadsideEmailMatching flag has been set.
				AND COALESCE(NULLIF(WE.EmailAddress1, ''), NULLIF(WE.EmailAddress2, '')) IS NOT NULL
				AND COALESCE(NULLIF(WE.SurnameField1, ''), NULLIF(WE.CompanyName, '')) IS NOT NULL
				AND COALESCE(NULLIF(WE.MatchedODSPersonID, 0), NULLIF(WE.MatchedODSOrganisationID, 0)) IS NULL -- And we haven't already matched a party using the Roadside match routines
		   )
	  )
AND ISNULL(WE.AuditID, 0) > 0
AND ISNULL(WE.PhysicalRowID, 0) > 0 
AND WE.DateTransferredToVWT IS NULL


