CREATE VIEW [SelectionOutput].[vwCATI]
AS
WITH PostalAddresses AS (
	SELECT
		CM.CaseID,
		CM.ContactMechanismID,
		PA.BuildingName,
		PA.SubStreet,
		PA.Street,
		PA.SubLocality,
		PA.Locality,
		PA.Town,
		PA.Region,
		PA.PostCode,
		C.Country,
		PA.CountryID
	FROM (
		SELECT
			CCM.CaseID,
			MAX(PA.ContactMechanismID) AS ContactMechanismID
		FROM Event.CaseContactMechanisms CCM
		INNER JOIN ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = CCM.ContactMechanismID
		GROUP BY CCM.CaseID
	) CM
	INNER JOIN ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = CM.ContactMechanismID
	INNER JOIN ContactMechanism.Countries C ON C.CountryID = PA.CountryID
),
EmailAddresses AS (
	SELECT
		CM.CaseID,
		CM.ContactMechanismID,
		EA.EmailAddress
	FROM (
		SELECT
			CCM.CaseID,
			MAX(EA.ContactMechanismID) AS ContactMechanismID
		FROM Event.CaseContactMechanisms CCM
		INNER JOIN ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = CCM.ContactMechanismID
		GROUP BY CCM.CaseID
	) CM
	INNER JOIN ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = CM.ContactMechanismID
)
SELECT DISTINCT
	SO.SelectionOutputPassword AS [Password],
	SO.CaseID AS [ID],
	CASE
		WHEN B.Brand = 'Jaguar' AND C.ModelDescription <> 'Unknown Vehicle' THEN B.Brand + ' ' + C.ModelDescription
		ELSE C.ModelDescription
	END AS [FullModel],
	CASE
		WHEN B.Brand = 'Jaguar' AND C.ModelDescription <> 'Unknown Vehicle' THEN B.Brand + ' ' + C.ModelDescription
		ELSE C.ModelDescription
	END AS [Model],
	B.Brand AS [sType],
	C.RegistrationNumber AS [CarReg],
	C.Title,
	C.FirstName AS [Initial],
	C.LastName AS [Surname],
	ISNULL(C.Title, '') + ' ' + ISNULL(C.FirstName, '') + ' ' + ISNULL(C.LastName, '') AS [Fullname],
	CASE D.Market
		WHEN 'China' THEN N'亲爱的客户'
		WHEN 'Russian Federation' THEN N'Здравствуйте'
		--FIX - RE-OUTPUT CATI CASES MISSING DEARNAME / SALUTATION IN ALL FILE
		ELSE Party.udfGetAddressingText(C.PartyID, C.QuestionnaireRequirementID, C.CountryID, C.LanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Salutation'))
	END AS [DearName],
	C.OrganisationName AS [CoName],
	PA.BuildingName AS [Add1],
	PA.SubStreet AS [Add2],
	PA.Street AS [Add3],
	PA.SubLocality AS [Add4],
	PA.Locality AS [Add5],
	PA.Town AS [Add6],
	PA.Region AS [Add7],
	PA.PostCode AS [Add8],
	'' AS [Add9],
	--PA.Country AS [CTRY],
	COALESCE(NULLIF(PA.Country,''),NULLIF(c.Country,'')) AS [CTRY],
	EA.EmailAddress AS [EmailAddress],
	C.DealerName AS [Dealer],
	CONVERT(VARCHAR, C.EventTypeID) + 
					SUBSTRING('000', 1, 3 - LEN(C.CountryID)) + 
					CONVERT(VARCHAR, C.CountryID) +
					SUBSTRING('00000', 1, 5 - LEN(C.ManufacturerPartyID)) + 
					CONVERT(Varchar, C.ManufacturerPartyID) +
					CONVERT(VARCHAR, C.SelectionTypeID) +
					CONVERT(VARCHAR, C.QuestionnaireVersion)
	AS [sno],
	ISNULL(C.CountryID, PA.CountryID) AS [ccode],
	C.ModelRequirementID AS [modelcode],
	C.LanguageID AS [lang],
	C.ManufacturerPartyID AS [manuf],
	C.GenderID AS [gender],
	C.QuestionnaireVersion AS [qver],
	'' AS [blank],
	SO.EventTypeID AS [etype],
	1 AS [reminder],
	SelectionOutput.udfGetWeekNumber(GETDATE()) AS [week],
	0 AS [test],
	0 AS [SampleFlag],
	'' AS [SalesServiceFile],
	SO.DealerCode,
	SO.VIN,
	SO.EventDate,
	SO.LandPhone,
	SO.WorkPhone,
	SO.MobilePhone,
	SO.PartyID,
	SO.GDDDealerCode, --v1.3
	SO.ReportingDealerPartyID, --v1.3
	SO.VariantID, --v1.3
	SO.ModelVariant, -- v1.3
	SO.ReOutputFLag,  --v1.7
	SO.[Queue],
	SO.[AssignedMode],
	SO.[RequiresManualDial],
	SO.[CallRecordingsCount],
	SO.[TimeZone],			
	SO.[CallOutcome],		
	SO.[PhoneNumber],		
	SO.[PhoneSource],		
	SO.[Language],			
	SO.[ExpirationTime],	
	SO.[HomePhoneNumber],	
	SO.[WorkPhoneNumber],	
	SO.[MobilePhoneNumber]
FROM SelectionOutput.CATI SO
INNER JOIN Meta.CaseDetails C ON SO.CaseID = C.CaseID
LEFT JOIN PostalAddresses PA ON PA.CaseID = C.CaseID
LEFT JOIN EmailAddresses EA ON EA.CaseID = C.CaseID
LEFT JOIN DW_JLRCSPDealers D ON D.OutletPartyID = C.DealerPartyID
INNER JOIN dbo.Brands B ON B.ManufacturerPartyID = C.ManufacturerPartyID;

