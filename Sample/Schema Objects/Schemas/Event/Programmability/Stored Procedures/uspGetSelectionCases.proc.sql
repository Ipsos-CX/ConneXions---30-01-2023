CREATE PROCEDURE [Event].[uspGetSelectionCases]
@SelectionRequirementID [dbo].[RequirementID], @IncludeCaseRejections BIT=0
AS

/*
		Purpose:	Returns the details of a given selection with rejected cases optionally included.  
		
		Version		Date				Developer			Comment
LIVE	1.0			??????????			Simon Peacock		Created
LIVE	1.1			04/04/2012			Attila Kubanda		BUG 6558 - RoadSide requires VIN in outputfile.
LIVE	1.2			18/04/2012			Attila Kubanda		BUG 6746 - People who had no valid Postaladdress due to NonSolicitation the countryid and versionid hasn't been populated. This update will write in the countryid where it is necessary.
LIVE	1.3			18/12/2012			Chris Ross			BUG 8135 - Additional fields required in selection output files.
LIVE	1.4			15/04/2013			Martin Riverol		BUG 8883 - Additional fields required in selection output files
LIVE	1.5			14/10/2014			Chris Ross			BUG 6061 - Change Jaguar ModelDescription CASE to do nothing where description is 'Unknown Vehicle'
LIVE	1.6			03/07/2015			Chris Ross			BUG 11595 - Add in missing country ID lookup for CRC and Roadside.
LIVE	1.7			26/01/2106			Chris Ross			BUG 12038 - Replace hardcoded OutletFuntionID statement with Event.EventTypes table lookup.
LIVE	1.8			23/03/2016			Chris Ledger		BUG 11874 - Add text to organisation name for Japan
LIVE	1.9			02/02/2017			Chris Ross			BUG 13549 - Add in alternative North America model and model variant values.
LIVE	1.10		19/10/2017			Chris Ross			BUG 13245 - Calculate whether bilingual invite required and populate bilingual columns accordingly.
LIVE	1.11		14/12/2017			Chris Ross			BUG 14439 - Modify the Model Description CASE statement to use the ManufacturerPartyID rather than @Brand.
LIVE	1.12		18/04/2018			Chris Ross			BUG 14399 - Exclude rows where the Party has a GDPR Erase request.
LIVE	1.13		05/06/2018			Chris Ledger		BUG 14399 - Exclude rows where the Party has a GDPR Right to Restriction.
LIVE	1.14		01/11/2018			Chris Ledger		BUG 15056 - Add I-Assitance Network
LIVE	1.15		26/05/2021			Eddie Thomas		Incorrect reference to OutletCode_GDD when adding in bilingual information. This has been changed to OutletCode			
LIVE	1.16		21/02/2022			Chris Ledger		TASK 728 - Set bilingual flag for Quebec General Enquiry & Roadside postcodes
LIVE	1.17		21/02/2022			Chris Ledger		TASK 728 - Set bilingual flag for Kazakhstan
LIVE	1.18		10/06/2022			Chris Ledger		TASK 729 - Remove Jaguar & CRC from the model/variant description
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- GET THE QuestionRequirementID FOR THE SELECTION
	DECLARE @QuestionnaireRequirementID dbo.RequirementID
	DECLARE @Brand dbo.OrganisationName
	DECLARE @Market dbo.Country				-- V1.8

	SELECT @QuestionnaireRequirementID = RR.RequirementIDPartOf,
		@Brand = BMQ.Brand,
		@Market = BMQ.Market				-- V1.8
	FROM Requirement.RequirementRollups RR
		INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON BMQ.QuestionnaireRequirementID = RR.RequirementIDPartOf
	WHERE RR.RequirementIDMadeUpOf = @SelectionRequirementID


	------------------------------------------------------------------------------------------------------------
	-- CREATE TEMP TABLE TO HOLD THE DATA
	------------------------------------------------------------------------------------------------------------
	CREATE TABLE #CaseDetails
	(
		VersionCode VARCHAR(200),
		SelectionTypeID SMALLINT,
		Manufacturer NVARCHAR(510),
		ManufacturerPartyID INT,
		QuestionnaireVersion TINYINT,
		CaseID INT,
		CaseRejection INT,
		Salutation NVARCHAR(500),
		Title NVARCHAR(200),
		FirstName NVARCHAR(100),
		LastName NVARCHAR(100),
		SecondLastName NVARCHAR(100),
		Addressee NVARCHAR(500),
		OrganisationName  NVARCHAR(510),
		GenderID TINYINT,
		LanguageID SMALLINT,
		CountryID SMALLINT,
		PartyID INT,
		EventTypeID SMALLINT,
		RegistrationNumber NVARCHAR(100),
		RegistrationDate DATETIME2,
		ModelDescription VARCHAR(100),
		ModelRequirementID INT,
		DealerCode NVARCHAR(20),
		DealerName NVARCHAR(150),
		PostalAddressContactMechanismID INT,
		BuildingName NVARCHAR(400),
		SubStreet NVARCHAR(400),
		Street NVARCHAR(400),
		SubLocality NVARCHAR(400),
		Locality NVARCHAR(400),
		Town NVARCHAR(400),
		Region NVARCHAR(400),
		PostCode NVARCHAR(60),
		Country VARCHAR(200),
		EmailAddressContactMechanismID INT,
		EmailAddress NVARCHAR(510),
		VIN NVARCHAR(50),
		EventType NVARCHAR(200),
		Telephone NVARCHAR(100),
		MobilePhone NVARCHAR(100),
		WorkTel NVARCHAR(100),
		SaleType NVARCHAR(1),
		EventDate DATETIME2,
		DealerPartyID INT,
		GDDDealerCode NVARCHAR(20),
		ReportingDealerPartyID INT,
		VariantID SMALLINT,
		ModelVariant VARCHAR(50),
		BilingualFlag BIT,							-- V1.10
		LanguageIDBilingual INT,					-- V1.10
		SalutationBilingual NVARCHAR(500)			-- V1.10
	)


	INSERT INTO #CaseDetails
	(
		SelectionTypeID,
		Manufacturer,
		ManufacturerPartyID,
		QuestionnaireVersion,
		CaseID,
		CaseRejection,
		Salutation,
		Title,
		FirstName,
		LastName,
		Addressee,
		OrganisationName,
		GenderID,
		LanguageID,
		CountryID,
		PartyID,
		EventTypeID,
		RegistrationNumber,
		ModelDescription,
		ModelRequirementID,
		DealerName,
		PostalAddressContactMechanismID,
		Country,
		EmailAddressContactMechanismID,
		VIN,
		RegistrationDate,
		EventType,
		SaleType,
		DealerCode,
		EventDate,
		SecondLastName,
		DealerPartyID,
		VariantID,
		ModelVariant
	)
	SELECT
		SelectionTypeID,
		@Brand AS Manufacturer,
		ManufacturerPartyID,
		QuestionnaireVersion,
		CaseID,
		0 AS CaseRejection,
		Party.udfGetAddressingText(PartyID, @QuestionnaireRequirementID, CountryID, LanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Salutation')) AS Salutation,
		Title, 
		COALESCE(NULLIF(FirstName, ''), NULLIF(Initials, '')) AS FirstName,
		LastName,
		Party.udfGetAddressingText(PartyID, @QuestionnaireRequirementID, CountryID, LanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Addressing')) AS Addressee,
		CASE WHEN @Market = 'Japan' AND LEN(ISNULL(OrganisationName,'')) > 0 AND LEN(ISNULL(LastName,'')) = 0 THEN OrganisationName + (SELECT OrganisationName FROM SelectionOutput.MarketSpecificOutputs WHERE Market = @Market)
			 ELSE OrganisationName END AS OrganisationName,					-- V1.8
		GenderID,
		LanguageID,
		CountryID,
		PartyID,
		EventTypeID,
		RegistrationNumber,
		CASE WHEN ModelDescription = 'CRC Unknown Vehicle' THEN 'Unknown Vehicle'											-- V1.18
			 --WHEN ManufacturerPartyID = 2 AND ModelDescription <> 'Unknown Vehicle' THEN 'Jaguar ' + ModelDescription		-- V1.5, V1.11, V1.18
			 ELSE ModelDescription END AS ModelDescription,
		ModelRequirementID,
		DealerName,
		PostalAddressContactMechanismID,
		Country,
		EmailAddressContactMechanismID,
		VIN,
		RegistrationDate,
		EventType,
		SaleType,
		DealerCode,
		EventDate,
		SecondLastName,
		DealerPartyID,
		VariantID,
		CASE WHEN ModelVariant = 'CRC Unknown Vehicle' THEN 'Unknown Vehicle'			-- V1.18
			 ELSE ModelVariant END AS ModelVariant
	FROM Meta.CaseDetails CD
	WHERE CD.SelectionRequirementID = @SelectionRequirementID
		AND NOT EXISTS (	SELECT ER.PartyID 
							FROM [$(AuditDB)].GDPR.ErasureRequests ER 
							WHERE ER.PartyID = CD.PartyID)  -- V1.12 - Exclude if a GDPR erasure request present
		AND NOT EXISTS (	SELECT NS.PartyID								-- V1.13
							FROM dbo.NonSolicitations NS
								INNER JOIN dbo.NonSolicitationTexts NST ON NS.NonSolicitationTextID = NST.NonSolicitationTextID
							WHERE NST.NonSolicitationText = 'GDPR Right to Restriction' 
								AND NS.PartyID = CD.PartyID
								AND NS.ThroughDate IS NULL)
	ORDER BY COALESCE(CD.LastName, CD.OrganisationName)


	/* V1.18 - We no longer use specific North American model/variants
	------------------------------------------------------------------------------------------------------------
	-- Replace Model Description and Model Variant for North American cases with alternative value				-- V1.9
	------------------------------------------------------------------------------------------------------------
	UPDATE CD
	SET CD.ModelDescription = CASE	WHEN CD.ManufacturerPartyID = 2 AND CD.ModelDescription <> 'Unknown Vehicle' THEN 'Jaguar ' + M.NorthAmericaModelDescription	   -- (see v1.5, above) ; v1.11
									ELSE M.NorthAmericaModelDescription END,
		CD.ModelVariant = MV.NorthAmericaVariant
	FROM #CaseDetails CD 
		INNER JOIN Vehicle.ModelVariants MV ON MV.VariantID = CD.VariantID
		INNER JOIN Vehicle.Models M ON M.ModelID = MV.ModelID
	WHERE CD.CountryID IN (	SELECT M.CountryID 
							FROM dbo.Regions R
								INNER JOIN dbo.Markets M ON M.RegionID = R.RegionID
							WHERE R.Region = 'North America NSC') 
	*/


	------------------------------------------------------------------------------------------------------------
	-- GET THE POSTAL ADDRESS DETAILS
	------------------------------------------------------------------------------------------------------------
	UPDATE CD
	SET CD.BuildingName = PA.BuildingName,
		CD.SubStreet = PA.SubStreetNumber + ' ' + PA.SubStreet,
		CD.Street = PA.StreetNumber + ' ' + PA.Street,
		CD.SubLocality = PA.SubLocality,
		CD.Locality = PA.Locality,
		CD.Town = PA.Town,
		CD.Region = PA.Region,
		CD.PostCode = PA.PostCode,
		CD.CountryID = CASE	WHEN CD.CountryID IS NULL THEN PA.CountryID 
							ELSE CD.CountryID END
	FROM #CaseDetails CD
		INNER JOIN ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = CD.PostalAddressContactMechanismID


	------------------------------------------------------------------------------------------------------------
	-- V1.6 Set the Dealer PartyID if not already set (e.g. CRC or Roadside)
	------------------------------------------------------------------------------------------------------------
	UPDATE CD
	SET CD.DealerPartyID = O.PartyID
	FROM #CaseDetails CD
		INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CD.CaseID
		INNER JOIN Event.EventPartyRoles EPR ON AEBI.EventID = EPR.EventID
		INNER JOIN Party.Organisations O ON O.PartyID = EPR.PartyID
	WHERE CD.DealerPartyID IS NULL


	------------------------------------------------------------------------------------------------------------
	-- V1.2 GET COUNTRY DETAILS IN CASE PARTY DOESN'T HAVE A POSTALADDRESS
	------------------------------------------------------------------------------------------------------------
	;WITH CTE_DealerCountries (DealerPartyID, CountryID) AS 
	(
		SELECT DISTINCT
			DC.PartyIDFrom, 
			DC.CountryID
		FROM ContactMechanism.DealerCountries DC
		UNION
		SELECT CRC.PartyIDFrom, 
			CRC.CountryID					-- V1.6
		FROM Party.CRCNetworks CRC
		UNION
		SELECT RN.PartyIDFrom, 
			RN.CountryID					-- V1.6
		FROM Party.RoadsideNetworks RN
		UNION
		SELECT IA.PartyIDFrom, 
			IA.CountryID					-- V1.14
		FROM Party.IAssistanceNetworks IA
	)
	UPDATE CD
	SET CD.CountryID = DC.CountryID
	FROM #CaseDetails CD
		INNER JOIN CTE_DealerCountries DC ON DC.DealerPartyID = CD.DealerPartyID
	WHERE CD.CountryID IS NULL

	------------------------------------------------------------------------------------------------------------
	-- GET THE EMAIL ADDRESS DETAILS
	------------------------------------------------------------------------------------------------------------
	UPDATE CD
	SET CD.EmailAddress = EA.EmailAddress
	FROM #CaseDetails CD
		INNER JOIN ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = CD.EmailAddressContactMechanismID

	
	-- SET THE VersionCode VALUE
	UPDATE CD
	SET CD.VersionCode = CONVERT(VARCHAR, CD.EventTypeID) + 
		SUBSTRING('000', 1, 3 - LEN(CD.CountryID)) + 
		CONVERT(VARCHAR, CD.CountryID) +
		SUBSTRING('00000', 1, 5 - LEN(CD.ManufacturerPartyID)) + 
		CONVERT(VARCHAR, CD.ManufacturerPartyID) +
		CONVERT(VARCHAR, CD.SelectionTypeID) +
		CONVERT(VARCHAR, CD.QuestionnaireVersion)
	FROM #CaseDetails CD


	UPDATE CD
	SET CD.Telephone = TN.ContactNumber
	FROM #CaseDetails CD
		INNER JOIN Event.CaseContactMechanisms CM ON CD.CaseID = CM.CaseID 
		INNER JOIN ContactMechanism.TelephoneNumbers TN ON CM.ContactMechanismID = TN.ContactMechanismID
		INNER JOIN ContactMechanism.ContactMechanismTypes CMT ON CM.ContactMechanismTypeID = CMT.ContactMechanismTypeID 
															AND CMT.ContactMechanismType = N'Phone (landline)' 


	UPDATE CD
	SET CD.WorkTel = TN.ContactNumber
	FROM #CaseDetails CD
		INNER JOIN Event.CaseContactMechanisms CM ON CD.CaseID = CM.CaseID 
		INNER JOIN ContactMechanism.TelephoneNumbers TN ON CM.ContactMechanismID = TN.ContactMechanismID
		INNER JOIN ContactMechanism.ContactMechanismTypes CMT ON CM.ContactMechanismTypeID = CMT.ContactMechanismTypeID 
															AND CMT.ContactMechanismType = N'Phone' 


	UPDATE CD
	SET CD.MobilePhone = TN.ContactNumber
	FROM #CaseDetails CD
		INNER JOIN Event.CaseContactMechanisms CM ON CD.CaseID = CM.CaseID 
		INNER JOIN ContactMechanism.TelephoneNumbers TN ON CM.ContactMechanismID = TN.ContactMechanismID
		INNER JOIN ContactMechanism.ContactMechanismTypes CMT ON CM.ContactMechanismTypeID = CMT.ContactMechanismTypeID 
															AND CMT.ContactMechanismType = N'Phone (mobile)' 


	------------------------------------------------------------------------------------------------------------
	-- WRITE NEW DEALER CODE AND TRANSFERPARTYID TO THE DETAILS TABLE
	------------------------------------------------------------------------------------------------------------
	UPDATE CD
	SET CD.GDDDealerCode = D.OutletCode_GDD,
		CD.ReportingDealerPartyID = D.TransferPartyID
	FROM #CaseDetails CD
	INNER JOIN Event.EventTypes ET ON ET.EventTypeID = CD.EventTypeID										-- V1.7
									AND ET.RelatedOutletFunctionID IS NOT NULL
	INNER JOIN (	SELECT DISTINCT
						OutletPartyID,
						OutletFunctionID,
						ISNULL(OutletCode_GDD, '') AS OutletCode_GDD,
						TransferPartyID
					FROM dbo.DW_JLRCSPDealers) D ON CD.DealerPartyID = D.OutletPartyID
													AND ET.RelatedOutletFunctionID = D.OutletFunctionID		-- V1.7

	
	------------------------------------------------------------------------------------------------------------
	-- V1.10 Calculate whether bilingual and populate columns accordingly
	------------------------------------------------------------------------------------------------------------
	DECLARE @CanadianFrenchLanguageID INT,
			@AmericanEnglishLanguageID INT
	
	SELECT @CanadianFrenchLanguageID = LanguageID FROM dbo.Languages WHERE Language = 'Canadian French (Canada)' 
	SELECT @AmericanEnglishLanguageID = LanguageID FROM dbo.Languages WHERE Language = 'American English (USA & Canada)' 

	-- Update Non-CRC recs using DealerCode lookup
	UPDATE CD
	SET	CD.BilingualFlag = 1,
		CD.LanguageID = @AmericanEnglishLanguageID,
		CD.LanguageIDBilingual = @CanadianFrenchLanguageID,
		CD.Salutation = Party.udfGetAddressingText(CD.PartyID, @QuestionnaireRequirementID, CD.CountryID, @AmericanEnglishLanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Salutation')),
		CD.Addressee = Party.udfGetAddressingText(CD.PartyID, @QuestionnaireRequirementID, CD.CountryID, @AmericanEnglishLanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Addressing')),
		CD.SalutationBilingual = Party.udfGetAddressingText(CD.PartyID, @QuestionnaireRequirementID, CD.CountryID, @CanadianFrenchLanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Salutation'))
	FROM #CaseDetails CD
	WHERE CD.EventType NOT IN ('CRC','CRC General Enquiry','Roadside')		-- V1.16
		AND CD.DealerCode IN (	SELECT D.OutletCode 
								FROM dbo.DW_JLRCSPDealers D 
								WHERE D.BilingualSelectionOutput = 1)		-- V1.15


	-- Update CRC recs using PostCode lookup
	UPDATE CD
	SET CD.BilingualFlag = 1,
		CD.LanguageID = @AmericanEnglishLanguageID,
		CD.LanguageIDBilingual = @CanadianFrenchLanguageID,
		CD.Salutation = Party.udfGetAddressingText(CD.PartyID, @QuestionnaireRequirementID, CD.CountryID, @AmericanEnglishLanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Salutation')),
		CD.Addressee = Party.udfGetAddressingText(CD.PartyID, @QuestionnaireRequirementID, CD.CountryID, @AmericanEnglishLanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Addressing')),
		CD.SalutationBilingual = Party.udfGetAddressingText(CD.PartyID, @QuestionnaireRequirementID, CD.CountryID, @CanadianFrenchLanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Salutation'))
	FROM #CaseDetails CD
		INNER JOIN SelectionOutput.BilingualOutputPostcodes BOP ON BOP.CountryID = CD.CountryID 
																  AND ISNULL(CD.PostCode,'') LIKE BOP.PostCodeMatchString 
																  AND BOP.Enabled = 1
	WHERE CD.EventType IN ('CRC','CRC General Enquiry','Roadside')		-- V1.16
	

	------------------------------------------------------------------------------------------------------------
	-- V1.17 Set bilingual flag for Kazakhstan and populate columns accordingly
	------------------------------------------------------------------------------------------------------------
	DECLARE @RussianLanguageID INT,
			@KazakhLanguageID INT
	
	SELECT @RussianLanguageID = LanguageID FROM dbo.Languages WHERE Language = 'Russian' 
	SELECT @KazakhLanguageID = LanguageID FROM dbo.Languages WHERE Language = 'Kazakh' 

	-- Update Non-CRC recs using DealerCode lookup
	UPDATE CD
	SET	CD.BilingualFlag = 1,
		CD.LanguageID = @RussianLanguageID,
		CD.LanguageIDBilingual = @KazakhLanguageID,
		CD.Salutation = Party.udfGetAddressingText(CD.PartyID, @QuestionnaireRequirementID, CD.CountryID, @RussianLanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Salutation')),
		CD.Addressee = Party.udfGetAddressingText(CD.PartyID, @QuestionnaireRequirementID, CD.CountryID, @RussianLanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Addressing')),
		CD.SalutationBilingual = Party.udfGetAddressingText(CD.PartyID, @QuestionnaireRequirementID, CD.CountryID, @KazakhLanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Salutation'))
	FROM #CaseDetails CD
	WHERE CD.EventType NOT IN ('CRC','CRC General Enquiry','Roadside')
		AND CD.CountryID = (	SELECT M.CountryID 
								FROM dbo.Markets M 
								WHERE M.Market = 'Russian Federation') 
		AND CD.DealerCode IN (	SELECT D.OutletCode 
								FROM dbo.DW_JLRCSPDealers D 
									INNER JOIN dbo.Franchises F ON D.OutletPartyID = F.OutletPartyID
																	AND D.OutletFunctionID = F.OutletFunctionID
								WHERE F.FranchiseCountry = 'Kazakhstan')

	
	-- Update CRC, General Enquiry & Roadside records using PostCode lookup
	UPDATE CD
	SET CD.BilingualFlag = 1,
		CD.LanguageID = @RussianLanguageID,
		CD.LanguageIDBilingual = @KazakhLanguageID,
		CD.Salutation = Party.udfGetAddressingText(CD.PartyID, @QuestionnaireRequirementID, CD.CountryID, @RussianLanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Salutation')),
		CD.Addressee = Party.udfGetAddressingText(CD.PartyID, @QuestionnaireRequirementID, CD.CountryID, @RussianLanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Addressing')),
		CD.SalutationBilingual = Party.udfGetAddressingText(CD.PartyID, @QuestionnaireRequirementID, CD.CountryID, @KazakhLanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Salutation'))
	FROM #CaseDetails CD
		INNER JOIN SelectionOutput.BilingualOutputPostcodes BOP ON BOP.CountryID = CD.CountryID 
																  AND ISNULL(CD.PostCode,'') LIKE BOP.PostCodeMatchString 
																  AND BOP.Enabled = 1
	WHERE CD.EventType IN ('CRC','CRC General Enquiry','Roadside')
		AND CD.CountryID = (	SELECT M.CountryID 
								FROM dbo.Markets M 
								WHERE M.Market = 'Russian Federation') 	


	------------------------------------------------------------------------------------------------------------
	-- GET THE REJECTIONS
	------------------------------------------------------------------------------------------------------------
	UPDATE CD
	SET CD.CaseRejection = 1
	FROM #CaseDetails CD
		INNER JOIN Event.CaseRejections CR ON CR.CaseID = CD.CaseID
	
		
	------------------------------------------------------------------------------------------------------------
	-- OUTPUT 
	------------------------------------------------------------------------------------------------------------
	SELECT
		PartyID,
		CaseID,
		ModelDescription,
		VIN,							-- V1.1 add VIN column
		Manufacturer,
		RegistrationNumber,
		Title,
		FirstName,
		LastName,
		Addressee,
		Salutation,
		OrganisationName,
		PostalAddressContactMechanismID,
		BuildingName,
		SubStreet,
		Street,
		SubLocality,
		Locality,
		Town,
		Region,
		PostCode,
		Country,
		DealerCode,						-- V1.3
		DealerName,
		VersionCode,
		CountryID,
		ModelRequirementID,
		LanguageID,
		ManufacturerPartyID,
		GenderID,
		QuestionnaireVersion,
		EventTypeID,
		EventDate,						-- V1.3
		SelectionTypeID,
		EmailAddressContactMechanismID,
		EmailAddress,
		Telephone,						-- V1.3
		MobilePhone,					-- V1.3
		WorkTel,						-- V1.3
		GDDDealerCode,					-- V1.4
		ReportingDealerPartyID,			-- V1.4
		VariantID,						-- V1.4
		ModelVariant,					-- V1.4
		BilingualFlag,					-- V1.10
		LanguageIDBilingual,			-- V1.10
		SalutationBilingual				-- V1.10
	FROM #CaseDetails
	WHERE CASE @IncludeCaseRejections	WHEN 1 THEN CaseRejection
										ELSE 0 END = CaseRejection

	DROP TABLE #CaseDetails


END TRY
BEGIN CATCH

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [$(ErrorDB)].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH