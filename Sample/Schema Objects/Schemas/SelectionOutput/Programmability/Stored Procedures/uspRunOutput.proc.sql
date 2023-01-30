CREATE PROCEDURE [SelectionOutput].[uspRunOutput]
@Brand [dbo].[OrganisationName], @Market [dbo].[Country], @Questionnaire [dbo].[Requirement], @FileNameTimeStamp CHAR (13)
AS
SET NOCOUNT ON


/*
	Purpose:	Populates the various selection output tables for use in the Selection Output package.  
		
	Version			Date			Developer			Comment
	1.0				ReleaseDate		Simon Peacock		Created
	1.1				18/12/2012		Chris Ross			BUG 8135 - Additional fields to be output.
	1.2				12/02/2013		Chris Ross			Add in SelectionOutputPassword
	1.3				15/04/2013		Martin Riverol		BUG 8883 - Additional fields required in selection output files	
	1.4				20/06/2013		Martin Riverol		BUG 5020 - Fix to stop re-outputted generating duplicate outputted rows
	1.5				09/01/2014		Chris Ross			BUG 9500 - Add in Mobile Phone Only and Mixed (Mobile and Email) outputs.
	1.6				14/02/2014		Ali Yuksel			BUG 9863 - @PostCodeRequired and @StreetRequired moved into the while loop
	1.7				08/10/2015		Chris Ross			BUG 11387 - Set ReOutputFlag on SelectionOutput.CATI table when record derived FROM re-output
	1.8				12/02/2016		Eddie Thomas		BUG 11906 - Summary model infomation added to SelectionOutput.Postal
	1.9				14/03/2016		Chris Ross			BUG 12226 - Modify the blacklist checks on Email addresses to include the AFRL funtionality.	
	1.10			23/03/2016		Chris Ledger		BUG 11874 - Exclude organisation salutation for Japan postal output
	1.11			05/08/2016		Eddie Thomas		BUG 12897 - Adding new fields to CATI output for Dimensions
	1.12			11/08/2016		Chris Ross			BUG 12859 - Add in new ContactMethodology for CATI +then+ Email contact ('Mixed (CATI & Email)')
	1.13			07/10/2016		Chris Ledger		BUG 13098 - Add in new ContactMethodology for Email and then SMS, Mixed (Email & SMS) and rename Mixed (SMS & Email) to avoid confusion
	1.14			22/10/2016		Chris Ledger		BUG 13098 - Add ReoutputIndicator for SMS
	1.15			23/10/2016		Chris Ledger		BUG 13323 - Only select CaseIDs with valid telephone number for CATI with Mixed (CATI & Email)
	1.16			06/02/2017		Chris Ledger		BUG 13422 - Populate SampleFlag field for Postal Output with PilotQuestionnaire code if present for Market/Dealer/Event Category 
	1.17			31/03/2017		Chris Ledger		BUG 13790 - Populate SampleFlag field for Postal Output with Code 3 for US/Canada Sales/Service
	1.18			07/04/2017		Eddie Thomas		BUG 13703 - CATI - Expiration/Selection date changes.
	1.19			13/04/2017		Chris Ledger		BUG 13853 - Set SampleFlag to 0 for all except US/Canada Postal.
	1.20			20/04/2017		Chris Ledger		BUG 13378 - Update Selection Output CATI With EmployeeName.
	1.21			27/06/2017		Chris Ledger		BUG 14053 - Undo Populate SampleFlag field for Postal Output with Code 3 for US/Canada Sales/Service
	1.22			04/09/2017		Eddie Thomas		BUG 14088 - CATI - Expiration/Selection date changes for UK Lost Leads
	1.23			24/10/2017		Chris Ross			BUG 14245 - Update to include population of new bilingual columns (excludes CATI).
	1.24			10/08/2018		Eddie Thomas		BUG 14797 - Portugal Roadside - Contact Methodology Change request
	1.25			05/04/2019		Eddie Thomas		Salesman information now retrieved from Event.AdditionalInfoSales instead of the Audit version of this table
	1.26			14/11/2019		Chris Ledger		BUG 16691 - Add ReoutputIndicator for Postal.
*/


DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	DECLARE @NOW	DATETIME,									-- V1.18
			@dtCATI	DATETIME									-- V1.18
		
	SET @NOW = GETDATE()										-- V1.18

	SET	@dtCATI	= DATEADD(WEEK, DATEDIFF(DAY, 0, @NOW)/7, 4)	-- V1.18

		
	
	
    
	-- GET ALL SelectionRequirementIDs FROM SelectionOutput.SelectionToOutput FOR THIS BRAND, MARKET AND QUESTIONNAIRE COMBINATION
	CREATE TABLE #SelectionRequirementIDs
	(
		[ID] INT IDENTITY(1,1) NOT NULL,
		SelectionRequirementID INT,
		QuestionnaireRequirementID INT,
		ValidateAFRLCodes BIT 
	)

	INSERT INTO #SelectionRequirementIDs (SelectionRequirementID, QuestionnaireRequirementID, ValidateAFRLCodes)
	SELECT O.SelectionRequirementID, 
		R.RequirementID, 
		QR.ValidateAFRLCodes
	FROM SelectionOutput.SelectionsToOutput O
		INNER JOIN Requirement.RequirementRollups RR ON RR.RequirementIDMadeUpOf = O.SelectionRequirementID
		INNER JOIN Requirement.Requirements R  ON R.RequirementID = RR.RequirementIDPartOf
		INNER JOIN Requirement.QuestionnaireRequirements QR ON QR.RequirementID = R.RequirementID
	WHERE O.Brand = @Brand
		AND O.Market = @Market
		AND O.Questionnaire = @Questionnaire
		AND ISNULL(O.SelectionRequirementID, 0) > 0

	DECLARE @SelectionRequirementID INT
	DECLARE @QuestionnaireRequirementID INT
	DECLARE @ValidateAFRLCodes BIT
	DECLARE @Counter INT
	

	SET @Counter = 1

	------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------
	WHILE @Counter <= (SELECT COUNT(*) FROM #SelectionRequirementIDs)
	BEGIN
		SELECT
			@SelectionRequirementID = SelectionRequirementID,
			@QuestionnaireRequirementID = QuestionnaireRequirementID,
			@ValidateAFRLCodes = ValidateAFRLCodes
		FROM #SelectionRequirementIDs 
		WHERE [ID] = @Counter

		-- FIND OUT WHICH METHODOLOGY WE'RE USING AND CALL THE APPROPRIATE STORED PROC
		DECLARE @ContactMethodologyTypeID INT		
		DECLARE @PostCodeRequired BIT
		DECLARE @StreetRequired BIT

		SELECT @ContactMethodologyTypeID = ContactMethodologyTypeID,
			@PostCodeRequired = PostCodeRequired,
			@StreetRequired = StreetRequired
		FROM dbo.vwBrandMarketQuestionnaireSampleMetadata
		WHERE QuestionnaireRequirementID = @QuestionnaireRequirementID
		
		-- SET THE ContactMethodologyTypeID VALUE IN SelectionOutput.SelectionToOutput SO WE CAN USE IT WHEN GENERATING THE OUTPUT FILES
		UPDATE SelectionOutput.SelectionsToOutput
		SET ContactMethodologyTypeID = @ContactMethodologyTypeID
		WHERE Brand = @Brand
			AND Market = @Market
			AND Questionnaire = @Questionnaire


		--------------------------------------------------------------------------------
		-- ONLY RUN OUTPUT IF ContactMethodologyTypeID not "Non Output"
		--------------------------------------------------------------------------------
		IF @ContactMethodologyTypeID <> (	SELECT ContactMethodologyTypeID 
											FROM SelectionOutput.ContactMethodologyTypes 
											WHERE ContactMethodologyType = 'Non Output')
		BEGIN
		
			-- GET THE CASE DETAILS
			INSERT INTO SelectionOutput.Base
			(
				PartyID,
				CaseID,
				ModelDescription,
				VIN,
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
				DealerCode,					-- V1.1
				DealerName,
				VersionCode,
				CountryID,
				ModelRequirementID,
				LanguageID,
				ManufacturerPartyID,
				GenderID,
				QuestionnaireVersion,
				EventTypeID,
				EventDate,					-- V1.1
				SelectionTypeID,
				EmailAddressContactMechanismID,
				EmailAddress,
				LandPhone,					-- V1.1
				MobilePhone,				-- V1.1
				WorkPhone,					-- V1.1
				GDDDealerCode,				-- V1.3
				ReportingDealerPartyID,		-- V1.3
				VariantID,					-- V1.3
				ModelVariant,				-- V1.3			
				BilingualFlag,				-- V1.23
				LanguageIDBilingual,		-- V1.23
				SalutationBilingual			-- V1.23
			)
			EXEC [Event].uspGetSelectionCases @SelectionRequirementID			

			-- GET or SET the SelectionOutputPassword value --------------------- V1.2
			UPDATE B
			SET B.SelectionOutputPassword = CASE	WHEN ISNULL(C.SelectionOutputPassword, '') <> '' THEN C.SelectionOutputPassword
													ELSE SelectionOutput.udfGeneratePassword() END 
			FROM SelectionOutput.Base B
				INNER JOIN [Event].Cases C ON C.CaseID = B.CaseID

			
			--------------------------------------------------------------------------------
			-- POSTAL ONLY
			--------------------------------------------------------------------------------
			IF @ContactMethodologyTypeID = (	SELECT ContactMethodologyTypeID 
												FROM SelectionOutput.ContactMethodologyTypes 
												WHERE ContactMethodologyType = 'Postal Only')
			BEGIN	
			
				-- GET THE DATA WITH VALID POSTAL ADDRESSES.  
				-- WE NEED TO USE THE @StreetRequired AND @PostCodeRequired FLAG TO DETERMINE WHAT CONSTITUTES A VALID ADDRESS.  
				-- WE WILL INCLUDE A VLAID EMAIL ADDRESS IF IT EXISTS
				
				;WITH Blacklist AS 
				(
					SELECT DISTINCT 
						PCM.PartyID, 
						EA.EmailAddress
					FROM ContactMechanism.PartyContactMechanisms PCM
						INNER JOIN ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = PCM.ContactMechanismID
						INNER JOIN ContactMechanism.BlacklistContactMechanisms BCM ON BCM.ContactMechanismID = PCM.ContactMechanismID
						INNER JOIN ContactMechanism.BlacklistStrings CMBS ON CMBS.BlacklistStringID = BCM.BlacklistStringID
						INNER JOIN ContactMechanism.BlacklistTypes CMBT ON CMBS.BlacklistTypeID = CMBT.BlacklistTypeID
				)
				INSERT INTO SelectionOutput.Postal
				(
					[Password],
					[ID],
					FullModel,
					Model,
					sType,
					CarReg,
					Title,
					Initial,
					Surname,
					Fullname,
					DearName,
					CoName,
					Add1,
					Add2,
					Add3,
					Add4,
					Add5,
					Add6,
					Add7,
					Add8,
					Add9,
					CTRY,
					EmailAddress,
					Dealer,
					sno,
					ccode,
					modelcode,
					lang,
					manuf,
					gender,
					qver,
					blank,
					etype,
					reminder,
					[week],
					test,
					SampleFlag,
					SalesServiceFile,
					DealerCode,
					VIN,
					EventDate,
					LandPhone,
					WorkPhone,
					MobilePhone,
					PartyID,
					GDDDealerCode,			-- V1.3
					ReportingDealerPartyID, -- V1.3
					VariantID,				-- V1.3
					ModelVariant,			-- V1.3
					BilingualFlag,			-- V1.23	
					langBilingual,			-- V1.23
					DearNameBilingual		-- V1.23
				)
				SELECT DISTINCT
					B.SelectionOutputPassword AS [Password],
					B.CaseID AS [ID],
					B.ModelDescription AS FullModel,
					B.ModelDescription AS Model,
					B.Manufacturer AS sType,
					B.RegistrationNumber AS CarReg,
					B.Title,
					B.FirstName AS Initial,
					B.LastName AS Surname,
					B.Addressee AS Fullname,
					CASE
						WHEN @Market = 'JPN' AND LEN(NULLIF(B.OrganisationName,''))>0 THEN ''
						ELSE B.Salutation END AS DearName,								-- V1.10
					B.OrganisationName AS CoName,
					B.BuildingName AS Add1,
					B.SubStreet AS Add2,
					B.Street AS Add3,
					B.SubLocality AS Add4,
					B.Locality AS Add5,
					B.Town AS Add6,
					B.Region AS Add7,
					B.PostCode AS Add8,
					'' AS Add9,
					B.Country AS CTRY,
					CASE	WHEN ISNULL(BL.PartyID, 0) = 0 THEN ''
							ELSE B.EmailAddress	END AS EmailAddress,
					B.DealerName AS Dealer,
					B.VersionCode AS sno,
					B.CountryID AS ccode,
					B.ModelRequirementID AS modelcode,
					B.LanguageID AS lang,
					B.ManufacturerPartyID AS manuf,
					B.GenderID AS gender,
					B.QuestionnaireVersion AS qver,
					'' AS blank,
					B.EventTypeID AS etype,
					1 AS reminder,
					SelectionOutput.udfGetWeekNumber(GETDATE()) AS [week],
					0 AS test,
					0 AS SampleFlag,			--	V1.19
					'' AS SalesServiceFile,
					B.DealerCode,
					B.VIN,
					B.EventDate,
					B.LandPhone,
					B.WorkPhone,
					B.MobilePhone,
					B.PartyID,
					B.GDDDealerCode,			-- V1.3
					B.ReportingDealerPartyID,	-- V1.3
					B.VariantID,				-- V1.3
					B.ModelVariant,				-- V1.3		
					B.BilingualFlag,			-- V1.23
					B.LanguageIDBilingual,		-- V1.23
					B.SalutationBilingual		-- V1.23	
				FROM SelectionOutput.Base B
					LEFT JOIN Blacklist BL ON BL.PartyID = B.PartyID 
											AND BL.EmailAddress = B.EmailAddress
				WHERE CASE	WHEN @StreetRequired = 1 THEN ISNULL(B.Street, '') 
							ELSE 'Street' END <> ''
					AND CASE	WHEN @PostCodeRequired = 1 THEN ISNULL(B.Postcode, '') 
								ELSE 'Postcode' END <> ''			
			
			END

			
			--------------------------------------------------------------------------------
			-- EMAIL ONLY
			--------------------------------------------------------------------------------
			IF @ContactMethodologyTypeID = (	SELECT ContactMethodologyTypeID 
												FROM SelectionOutput.ContactMethodologyTypes 
												WHERE ContactMethodologyType = 'Email Only')
			BEGIN	
			
				-- GET THE DATA WITH VALID EMAILS
				;WITH Blacklist AS 
				(
					SELECT DISTINCT 
						PCM.PartyID, 
						EA.EmailAddress
					FROM ContactMechanism.PartyContactMechanisms PCM
						INNER JOIN ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = PCM.ContactMechanismID
						INNER JOIN ContactMechanism.BlacklistContactMechanisms BCM ON BCM.ContactMechanismID = PCM.ContactMechanismID
						INNER JOIN ContactMechanism.BlacklistStrings CMBS ON CMBS.BlacklistStringID = BCM.BlacklistStringID
						INNER JOIN ContactMechanism.BlacklistTypes CMBT ON CMBS.BlacklistTypeID = CMBT.BlacklistTypeID
																		AND ISNULL(CMBT.AFRLFilter, 0) = ISNULL(@ValidateAFRLCodes, 0)  -- V1.9 - ensure AFRL any filtering is applied
				), Reoutput AS 
				(
					SELECT DISTINCT CCMO.CaseID
					FROM [Event].CaseContactMechanismOutcomes CCMO
						INNER JOIN ContactMechanism.OutcomeCodes OC ON OC.OutcomeCode = CCMO.OutcomeCode
					WHERE OC.CausesReOutput = 1
						AND OC.OutcomeCodeTypeID = (	SELECT OutcomeCodeTypeID 
														FROM ContactMechanism.OutcomeCodeTypes 
														WHERE OutcomeCodeType = 'Online') -- EMAIL
				)
				INSERT INTO SelectionOutput.Email
				(
					[Password],
					[ID],
					FullModel,
					Model,
					VIN,
					sType,
					CarReg,
					Title,
					Initial,
					Surname,
					Fullname,
					DearName,
					CoName,
					Add1,
					Add2,
					Add3,
					Add4,
					Add5,
					Add6,
					Add7,
					Add8,
					Add9,
					CTRY,
					EmailAddress,
					Dealer,
					sno,
					ccode,
					modelcode,
					lang,
					manuf,
					gender,
					qver,
					blank,
					etype,
					reminder,
					[week],
					test,
					SampleFlag,
					SalesServiceFile,
					DealerCode,
					EventDate,
					LandPhone,
					WorkPhone,
					MobilePhone,
					PartyID,
					GDDDealerCode,			-- V1.3
					ReportingDealerPartyID, -- V1.3
					VariantID,				-- V1.3
					ModelVariant,			-- V1.3
					BilingualFlag,			-- V1.23	
					langBilingual,			-- V1.23
					DearNameBilingual		-- V1.23
				)
				SELECT DISTINCT
					B.SelectionOutputPassword AS [Password],
					B.CaseID AS [ID],
					B.ModelDescription AS FullModel,
					B.ModelDescription AS Model,
					B.VIN,
					B.Manufacturer AS sType,
					B.RegistrationNumber AS CarReg,
					B.Title,
					B.FirstName AS Initial,
					B.LastName AS Surname,
					B.Addressee AS Fullname,
					B.Salutation AS DearName,
					B.OrganisationName AS CoName,
					B.BuildingName AS Add1,
					B.SubStreet AS Add2,
					B.Street AS Add3,
					B.SubLocality AS Add4,
					B.Locality AS Add5,
					B.Town AS Add6,
					B.Region AS Add7,
					B.PostCode AS Add8,
					'' AS Add9,
					B.Country AS CTRY,
					B.EmailAddress,
					B.DealerName AS Dealer,
					B.VersionCode AS sno,
					B.CountryID AS ccode,
					B.ModelRequirementID AS modelcode,
					B.LanguageID AS lang,
					B.ManufacturerPartyID AS manuf,
					B.GenderID AS gender,
					B.QuestionnaireVersion AS qver,
					'' AS blank,
					B.EventTypeID AS etype,
					1 AS reminder,
					SelectionOutput.udfGetWeekNumber(GETDATE()) AS [week],
					0 AS test,
					0 AS SampleFlag,			-- V1.19
					'' AS SalesServiceFile,
					B.DealerCode,
					B.EventDate,
					B.LandPhone,
					B.WorkPhone,
					B.MobilePhone,
					B.PartyID,
					B.GDDDealerCode,			-- V1.3
					B.ReportingDealerPartyID,	-- V1.3
					B.VariantID,				-- V1.3
					B.ModelVariant,				-- V1.3
					B.BilingualFlag,			-- V1.23
					B.LanguageIDBilingual,		-- V1.23
					B.SalutationBilingual		-- V1.23	
				FROM SelectionOutput.Base B
					LEFT JOIN Blacklist BL ON BL.PartyID = B.PartyID 
											AND BL.EmailAddress = B.EmailAddress
					LEFT JOIN Reoutput RO ON RO.CaseID = B.CaseID
				WHERE ISNULL(B.EmailAddressContactMechanismID, 0) > 0 
					AND BL.PartyID IS NULL
					AND RO.CaseID IS NULL

			END
	
	
			--------------------------------------------------------------------------------
			-- TELEPHONE ONLY
			--------------------------------------------------------------------------------
			IF @ContactMethodologyTypeID = (	SELECT ContactMethodologyTypeID 
												FROM SelectionOutput.ContactMethodologyTypes 
												WHERE ContactMethodologyType = 'CATI')
			BEGIN	
			
				INSERT INTO SelectionOutput.CATI
				(
					VIN,
					DealerCode,
					ModelDesc,
					CoName,
					Add1,
					Add2,
					Add3,
					Add4,
					Add5,
					LandPhone,
					WorkPhone,
					MobilePhone,
					PartyID,
					CaseID,
					DateOutput,
					JLR,
					EventTypeID,
					RegNumber,
					RegDate,
					LocalName,
					EventDate,
					SelectionOutputPassword,
					GDDDealerCode,			-- V1.3
					ReportingDealerPartyID, -- V1.3
					VariantID,				-- V1.3
					ModelVariant,			-- V1.3
					[Queue],				-- V1.11
					AssignedMode,			-- V1.11
					RequiresManualDial,		-- V1.11
					CallRecordingsCount,	-- V1.11
					TimeZone,				-- V1.11
					CallOutcome,			-- V1.11
					PhoneNumber,			-- V1.11
					PhoneSource,			-- V1.11
					[Language],				-- V1.11
					ExpirationTime,			-- V1.11
					HomePhoneNumber,		-- V1.11
					WorkPhoneNumber,		-- V1.11
					MobilePhoneNumber		-- V1.11
				)
				SELECT
					CB.VIN,
					CB.DealerCode,
					ModelDesc,
					CoName,
					Add1,
					Add2,
					Add3,
					Add4,
					Add5,
					LandPhone,
					WorkPhone,
					MobilePhone,
					CB.PartyID,
					CB.CaseID,
					DateOutput,
					JLR,
					CB.EventTypeID,
					RegNumber,
					RegDate,
					LocalName,
					CB.EventDate,
					SelectionOutputPassword,
					GDDDealerCode,			-- V1.3
					ReportingDealerPartyID, -- V1.3
					CB.VariantID,			-- V1.3
					CB.ModelVariant,		-- V1.3
					'FRESH' AS [Queue],
					'Phone' AS AssignedMode,
					1 AS RequiresManualDial,
					1 AS CallRecordingsCount,
					ISNULL(CT.TimeZoneID,0) AS TimeZone, 
					'Undialled' AS CallOutcome, 
					COALESCE	(NULLIF(SelectionOutput.udfFormatTelNoForDimensions(CB.MobilePhone, CD.CountryID), ''),
								NULLIF(SelectionOutput.udfFormatTelNoForDimensions(CB.LandPhone, CD.CountryID), ''),
								NULLIF(SelectionOutput.udfFormatTelNoForDimensions(CB.WorkPhone, CD.CountryID), ''),
								'') AS PhoneNumber,
					CASE	WHEN ISNULL(CB.MobilePhone, '') <> '' THEN 'MobilePhoneNumber'
							WHEN ISNULL(CB.LandPhone, '') <> '' THEN 'HomePhoneNumber'
							WHEN ISNULL(CB.WorkPhone, '') <> '' THEN 'WorkPhoneNumber'
							ELSE ''	END AS PhoneSource,
					CASE	WHEN LV.LanguageID IS NULL THEN ISNULL(DL.LanguageCode, '')
							ELSE ISNULL(DL2.LanguageCode, '') END AS [Language], 
					CONVERT (DATETIME,CONVERT(VARCHAR(10),DATEADD(dd, BMQ.NumDaysToExpireOnlineQuestionnaire, @dtCATI), 120) + '  23:59:59') AS ExpirationTime,																																														-- V1.22
					SelectionOutput.udfFormatTelNoForDimensions(CB.LandPhone, CD.CountryID) AS HomePhoneNumber,
					SelectionOutput.udfFormatTelNoForDimensions(CB.WorkPhone, CD.CountryID) AS WorkPhoneNumber,
					SelectionOutput.udfFormatTelNoForDimensions(CB.MobilePhone, CD.CountryID) AS MobilePhoneNumber
				FROM SelectionOutput.vwCATIBase CB
					INNER JOIN Meta.CaseDetails CD ON CB.CaseID	= CD.CaseID
					INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata	MD ON CD.QuestionnaireRequirementID = MD.QuestionnaireRequirementID
					INNER JOIN dbo.BrandMarketQuestionnaireMetadata BMQ	ON MD.BMQID = BMQ.BMQID
					LEFT JOIN Dimensions.CountryAndTimezone CT ON CD.CountryID = CT.CountryID
					LEFT JOIN Dimensions.DimensionsLanguage DL ON CD.LanguageID	= DL.LanguageID
					LEFT JOIN Dimensions.LanguageVariation LV ON CD.LanguageID = LV.LanguageID 
																	AND CD.CountryID = LV.CountryID
					LEFT JOIN Dimensions.DimensionsLanguage DL2	ON LV.DimensionsLanguageID = DL2.DimensionsLanguageID
				
			END


			--------------------------------------------------------------------------------
			-- SMS ONLY														  -- V1.5
			--------------------------------------------------------------------------------
			IF @ContactMethodologyTypeID = (	SELECT ContactMethodologyTypeID 
												FROM SelectionOutput.ContactMethodologyTypes 
												WHERE ContactMethodologyType = 'SMS Only')
			BEGIN	
			
				-- GET THE DATA WITH VALID MOBILE PHONE NUMBERS
				;WITH Blacklist AS 
				(
					SELECT DISTINCT
						PCM.PartyID, 
						TN.ContactNumber
					FROM SelectionOutput.Base B
						INNER JOIN ContactMechanism.PartyContactMechanisms PCM ON PCM.PartyID = B.PartyID
						INNER JOIN ContactMechanism.TelephoneNumbers TN ON TN.ContactMechanismID = PCM.ContactMechanismID
						INNER JOIN ContactMechanism.BlacklistContactMechanisms BCM ON BCM.ContactMechanismID = PCM.ContactMechanismID
						--INNER JOIN ContactMechanism.BlacklistStrings CMBS ON CMBS.BlacklistStringID = BCM.BlacklistStringID
						--INNER JOIN ContactMechanism.BlacklistTypes CMBT ON CMBS.BlacklistTypeID = CMBT.BlacklistTypeID
				), Reoutput AS 
				(
					SELECT DISTINCT 
						CCMO.CaseID
					FROM [Event].CaseContactMechanismOutcomes CCMO
						INNER JOIN ContactMechanism.OutcomeCodes OC ON OC.OutcomeCode = CCMO.OutcomeCode
					WHERE OC.CausesReOutput = 1
						AND OC.OutcomeCodeTypeID = (	SELECT OutcomeCodeTypeID 
														FROM ContactMechanism.OutcomeCodeTypes 
														WHERE OutcomeCodeType = 'SMS')
				)
				INSERT INTO SelectionOutput.SMS
				(
					[Password],
					[ID],
					FullModel,
					Model,
					VIN,
					sType,
					CarReg,
					Title,
					Initial,
					Surname,
					Fullname,
					DearName,
					CoName,
					Add1,
					Add2,
					Add3,
					Add4,
					Add5,
					Add6,
					Add7,
					Add8,
					Add9,
					CTRY,
					EmailAddress,
					Dealer,
					sno,
					ccode,
					modelcode,
					lang,
					manuf,
					gender,
					qver,
					blank,
					etype,
					reminder,
					[week],
					test,
					SampleFlag,
					SalesServiceFile,
					DealerCode,
					EventDate,
					LandPhone,
					WorkPhone,
					MobilePhone,
					PartyID,
					GDDDealerCode,			-- V1.3
					ReportingDealerPartyID, -- V1.3
					VariantID,				-- V1.3
					ModelVariant,			-- V1.3
					BilingualFlag,			-- V1.23	
					langBilingual,			-- V1.23
					DearNameBilingual,		-- V1.23
					FirstName				-- V1.24
				)
				SELECT DISTINCT
					B.SelectionOutputPassword AS [Password],
					B.CaseID AS [ID],
					B.ModelDescription AS FullModel,
					B.ModelDescription AS Model,
					B.VIN,
					B.Manufacturer AS sType,
					B.RegistrationNumber AS CarReg,
					B.Title,
					B.FirstName AS Initial,
					B.LastName AS Surname,
					B.Addressee AS Fullname,
					B.Salutation AS DearName,
					B.OrganisationName AS CoName,
					B.BuildingName AS Add1,
					B.SubStreet AS Add2,
					B.Street AS Add3,
					B.SubLocality AS Add4,
					B.Locality AS Add5,
					B.Town AS Add6,
					B.Region AS Add7,
					B.PostCode AS Add8,
					'' AS Add9,
					B.Country AS CTRY,
					B.EmailAddress,
					B.DealerName AS Dealer,
					B.VersionCode AS sno,
					B.CountryID AS ccode,
					B.ModelRequirementID AS modelcode,
					B.LanguageID AS lang,
					B.ManufacturerPartyID AS manuf,
					B.GenderID AS gender,
					B.QuestionnaireVersion AS qver,
					'' AS blank,
					B.EventTypeID AS etype,
					1 AS reminder,
					SelectionOutput.udfGetWeekNumber(GETDATE()) AS [week],
					0 AS test,
					0 AS SampleFlag,			-- V1.19
					'' AS SalesServiceFile,
					B.DealerCode,
					B.EventDate,
					B.LandPhone,
					B.WorkPhone,
					B.MobilePhone,
					B.PartyID,
					B.GDDDealerCode,			-- V1.3
					B.ReportingDealerPartyID,	-- V1.3
					B.VariantID,				-- V1.3
					B.ModelVariant,				-- V1.3
					B.BilingualFlag,			-- V1.23
					B.LanguageIDBilingual,		-- V1.23
					B.SalutationBilingual,		-- V1.23	
					B.FirstName					-- V1.24
				FROM SelectionOutput.Base B
					LEFT JOIN Blacklist BL ON BL.PartyID = B.PartyID 
											AND BL.ContactNumber = B.MobilePhone
					LEFT JOIN Reoutput RO ON RO.CaseID = B.CaseID
				WHERE ISNULL(B.MobilePhone, '') <> ''						-- V1.5 
					AND BL.PartyID IS NULL
					AND RO.CaseID IS NULL

			END

					
			--------------------------------------------------------------------------------
			-- MIXED EMAIL AND POSTAL
			--------------------------------------------------------------------------------
			IF @ContactMethodologyTypeID = (	SELECT ContactMethodologyTypeID 
												FROM SelectionOutput.ContactMethodologyTypes 
												WHERE ContactMethodologyType = 'Mixed (email & postal)')
			BEGIN	
			
				-- WE'RE IN A MIXED METHODOLOGY SO WE'RE NOT FORCING RECORDS TO HAVE AN EMAIL ADDRESS.
				-- WE JUST WANT TO GET ALL OF THE SELECTED RECORDS THAT DO HAVE A VALID EMAIL AND EMAIL THE INVITATION.
				
				-- GET THE DATA WITH EMAILS FIRST OF ALL
				;WITH Blacklist AS 
				(
					SELECT DISTINCT 
						PCM.PartyID, 
						EA.EmailAddress
					FROM ContactMechanism.PartyContactMechanisms PCM
						INNER JOIN ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = PCM.ContactMechanismID
						INNER JOIN ContactMechanism.BlacklistContactMechanisms BCM ON BCM.ContactMechanismID = PCM.ContactMechanismID
						INNER JOIN ContactMechanism.BlacklistStrings CMBS ON CMBS.BlacklistStringID = BCM.BlacklistStringID
						INNER JOIN ContactMechanism.BlacklistTypes CMBT ON CMBS.BlacklistTypeID = CMBT.BlacklistTypeID
																		AND ISNULL(CMBT.AFRLFilter, 0) = ISNULL(@ValidateAFRLCodes, 0)  -- V1.9 - ensure AFRL filtering is applied
				), Reoutput AS 
				(
					SELECT DISTINCT 
						CCMO.CaseID
					FROM [Event].CaseContactMechanismOutcomes CCMO
						INNER JOIN ContactMechanism.OutcomeCodes OC ON OC.OutcomeCode = CCMO.OutcomeCode
					WHERE OC.CausesReOutput = 1
						AND OC.OutcomeCodeTypeID = (	SELECT OutcomeCodeTypeID 
														FROM ContactMechanism.OutcomeCodeTypes 
														WHERE OutcomeCodeType = 'Online') -- EMAIL
				)
				INSERT INTO SelectionOutput.Email
				(
					[Password],
					[ID],
					FullModel,
					Model,
					sType,
					CarReg,
					Title,
					Initial,
					Surname,
					Fullname,
					DearName,
					CoName,
					Add1,
					Add2,
					Add3,
					Add4,
					Add5,
					Add6,
					Add7,
					Add8,
					Add9,
					CTRY,
					EmailAddress,
					Dealer,
					sno,
					ccode,
					modelcode,
					lang,
					manuf,
					gender,
					qver,
					blank,
					etype,
					reminder,
					[week],
					test,
					SampleFlag,
					SalesServiceFile,
					DealerCode,
					VIN,
					EventDate,
					LandPhone,
					WorkPhone,
					MobilePhone,
					PartyID,
					GDDDealerCode,			-- V1.3
					ReportingDealerPartyID,	-- V1.3
					VariantID,				-- V1.3
					ModelVariant,			-- V1.3
					BilingualFlag,			-- V1.23	
					langBilingual,			-- V1.23
					DearNameBilingual		-- V1.23					
				)
				SELECT DISTINCT
					B.SelectionOutputPassword AS [Password],
					B.CaseID AS [ID],
					B.ModelDescription AS FullModel,
					B.ModelDescription AS Model,
					B.Manufacturer AS sType,
					B.RegistrationNumber AS CarReg,
					B.Title,
					B.FirstName AS Initial,
					B.LastName AS Surname,
					B.Addressee AS Fullname,
					B.Salutation AS DearName,
					B.OrganisationName AS CoName,
					B.BuildingName AS Add1,
					B.SubStreet AS Add2,
					B.Street AS Add3,
					B.SubLocality AS Add4,
					B.Locality AS Add5,
					B.Town AS Add6,
					B.Region AS Add7,
					B.PostCode AS Add8,
					'' AS Add9,
					B.Country AS CTRY,
					B.EmailAddress,
					B.DealerName AS Dealer,
					B.VersionCode AS sno,
					B.CountryID AS ccode,
					B.ModelRequirementID AS modelcode,
					B.LanguageID AS lang,
					B.ManufacturerPartyID AS manuf,
					B.GenderID AS gender,
					B.QuestionnaireVersion AS qver,
					'' AS blank,
					B.EventTypeID AS etype,
					1 AS reminder,
					SelectionOutput.udfGetWeekNumber(GETDATE()) AS [week],
					0 AS test,
					0 AS SampleFlag,			-- V1.19
					'' AS SalesServiceFile,
					B.DealerCode,
					B.VIN,
					B.EventDate,
					B.LandPhone,
					B.WorkPhone,
					B.MobilePhone,
					B.PartyID,
					B.GDDDealerCode,			-- V1.3
					B.ReportingDealerPartyID,	-- V1.3
					B.VariantID,				-- V1.3
					B.ModelVariant,				-- V1.3
					B.BilingualFlag,			-- V1.23
					B.LanguageIDBilingual,		-- V1.23
					B.SalutationBilingual		-- V1.23	
				FROM SelectionOutput.Base B
					LEFT JOIN Blacklist BL ON BL.PartyID = B.PartyID 
												AND BL.EmailAddress = B.EmailAddress
					LEFT JOIN Reoutput RO ON RO.CaseID = B.CaseID
				WHERE ISNULL(B.EmailAddressContactMechanismID, 0) > 0 
					AND BL.PartyID IS NULL
					AND RO.CaseID IS NULL

				
				-- NOW GET THE DATA WITHOUT VALID EMAILS BUT WITH VALID POSTAL ADDRESSES.  
				-- WE NEED TO USE THE @StreetRequired AND @PostCodeRequired FLAG TO DETERMINE WHAT CONSTITUTES A VALID ADDRESS.  
				INSERT INTO SelectionOutput.Postal
				(
					[Password],
					[ID],
					FullModel,
					Model,
					sType,
					CarReg,
					Title,
					Initial,
					Surname,
					Fullname,
					DearName,
					CoName,
					Add1,
					Add2,
					Add3,
					Add4,
					Add5,
					Add6,
					Add7,
					Add8,
					Add9,
					CTRY,
					EmailAddress,
					Dealer,
					sno,
					ccode,
					modelcode,
					lang,
					manuf,
					gender,
					qver,
					blank,
					etype,
					reminder,
					[week],
					test,
					SampleFlag,
					SalesServiceFile,
					DealerCode,
					VIN,
					EventDate,
					LandPhone,
					WorkPhone,
					MobilePhone,
					PartyID,
					GDDDealerCode,			-- V1.3
					ReportingDealerPartyID, -- V1.3
					VariantID,				-- V1.3
					ModelVariant,			-- V1.3
					BilingualFlag,			-- V1.23	
					langBilingual,			-- V1.23
					DearNameBilingual		-- V1.23					
				)
				SELECT DISTINCT
					B.SelectionOutputPassword AS [Password],
					B.CaseID AS [ID],
					B.ModelDescription AS FullModel,
					B.ModelDescription AS Model,
					B.Manufacturer AS sType,
					B.RegistrationNumber AS CarReg,
					B.Title,
					B.FirstName AS Initial,
					B.LastName AS Surname,
					B.Addressee AS Fullname,
					B.Salutation AS DearName,
					B.OrganisationName AS CoName,
					B.BuildingName AS Add1,
					B.SubStreet AS Add2,
					B.Street AS Add3,
					B.SubLocality AS Add4,
					B.Locality AS Add5,
					B.Town AS Add6,
					B.Region AS Add7,
					B.PostCode AS Add8,
					'' AS Add9,
					B.Country AS CTRY,
					'' AS EmailAddress, -- DON'T INLCUDE THE EMAIL ADDRESS IN POSTAL OUTPUT FOR MIXED METHODOLOGY
					B.DealerName AS Dealer,
					B.VersionCode AS sno,
					B.CountryID AS ccode,
					B.ModelRequirementID AS modelcode,
					B.LanguageID AS lang,
					B.ManufacturerPartyID AS manuf,
					B.GenderID AS gender,
					B.QuestionnaireVersion AS qver,
					'' AS blank,
					B.EventTypeID AS etype,
					1 AS reminder,
					SelectionOutput.udfGetWeekNumber(GETDATE()) AS [week],
					0 AS test,
					0 AS SampleFlag,			-- V1.19
					'' AS SalesServiceFile,
					B.DealerCode,
					B.VIN,
					B.EventDate	,
					B.LandPhone,
					B.WorkPhone,
					B.MobilePhone,
					B.PartyID,
					B.GDDDealerCode,			-- V1.3
					B.ReportingDealerPartyID,	-- V1.3
					B.VariantID,				-- V1.3
					B.ModelVariant,				-- V1.3							
					B.BilingualFlag,			-- V1.23
					B.LanguageIDBilingual,		-- V1.23
					B.SalutationBilingual		-- V1.23	
				FROM SelectionOutput.Base B
					LEFT JOIN SelectionOutput.Email E ON E.ID = B.CaseID
				WHERE CASE	WHEN @StreetRequired = 1 THEN ISNULL(B.Street, '') 
							ELSE 'Street' END <> ''
					AND CASE	WHEN @PostCodeRequired = 1 THEN ISNULL(B.Postcode, '') 
								ELSE 'Postcode' END <> ''
					AND E.ID IS NULL
			
			END

						
			--------------------------------------------------------------------------------
			-- MIXED SMS AND EMAIL   (Use SMS in pref over Email)	-- V1.13 Just Swapped ContactMethodology Text around to avoid confusion
			--------------------------------------------------------------------------------
			IF @ContactMethodologyTypeID = (	SELECT ContactMethodologyTypeID 
												FROM SelectionOutput.ContactMethodologyTypes 
												WHERE ContactMethodologyType = 'Mixed (SMS & Email)')	-- V1.13
			BEGIN	
			
				-- WE'RE IN A MIXED METHODOLOGY SO WE'RE NOT FORCING RECORDS TO HAVE AN SMS ADDRESS.
				-- WE JUST WANT TO GET ALL OF THE SELECTED RECORDS THAT DO HAVE A VALID SMS AND SMS THE INVITATION.
				
				-- GET THE DATA WITH SMS FIRST OF ALL
				
				-- GET THE DATA WITH VALID MOBILE PHONE NUMBERS
				;WITH Blacklist AS 
				(
					SELECT DISTINCT 
						PCM.PartyID, 
						TN.ContactNumber
					FROM SelectionOutput.Base B
						INNER JOIN ContactMechanism.PartyContactMechanisms PCM ON PCM.PartyID = B.PartyID
						INNER JOIN ContactMechanism.TelephoneNumbers TN ON TN.ContactMechanismID = PCM.ContactMechanismID
						INNER JOIN ContactMechanism.BlacklistContactMechanisms BCM ON BCM.ContactMechanismID = PCM.ContactMechanismID
						--INNER JOIN ContactMechanism.BlacklistStrings CMBS ON CMBS.BlacklistStringID = BCM.BlacklistStringID
						--INNER JOIN ContactMechanism.BlacklistTypes CMBT ON CMBS.BlacklistTypeID = CMBT.BlacklistTypeID
				), Reoutput AS 
				(
					SELECT DISTINCT 
						CCMO.CaseID
					FROM [Event].CaseContactMechanismOutcomes CCMO
						INNER JOIN ContactMechanism.OutcomeCodes OC ON OC.OutcomeCode = CCMO.OutcomeCode
					WHERE OC.CausesReOutput = 1
						AND OC.OutcomeCodeTypeID = (	SELECT OutcomeCodeTypeID 
														FROM ContactMechanism.OutcomeCodeTypes 
														WHERE OutcomeCodeType = 'SMS')
				)
				INSERT INTO SelectionOutput.SMS
				(
					[Password],
					[ID],
					FullModel,
					Model,
					VIN,
					sType,
					CarReg,
					Title,
					Initial,
					Surname,
					Fullname,
					DearName,
					CoName,
					Add1,
					Add2,
					Add3,
					Add4,
					Add5,
					Add6,
					Add7,
					Add8,
					Add9,
					CTRY,
					EmailAddress,
					Dealer,
					sno,
					ccode,
					modelcode,
					lang,
					manuf,
					gender,
					qver,
					blank,
					etype,
					reminder,
					[week],
					test,
					SampleFlag,
					SalesServiceFile,
					DealerCode,
					EventDate,
					LandPhone,
					WorkPhone,
					MobilePhone,
					PartyID,
					GDDDealerCode,			-- V1.3
					ReportingDealerPartyID, -- V1.3
					VariantID,				-- V1.3
					ModelVariant,			-- V1.3
					BilingualFlag,			-- V1.23	
					langBilingual,			-- V1.23
					DearNameBilingual,		-- V1.23
					FirstName				-- V1.24					
				)
				SELECT DISTINCT
					B.SelectionOutputPassword AS [Password],
					B.CaseID AS [ID],
					B.ModelDescription AS FullModel,
					B.ModelDescription AS Model,
					B.VIN,
					B.Manufacturer AS sType,
					B.RegistrationNumber AS CarReg,
					B.Title,
					B.FirstName AS Initial,
					B.LastName AS Surname,
					B.Addressee AS Fullname,
					B.Salutation AS DearName,
					B.OrganisationName AS CoName,
					B.BuildingName AS Add1,
					B.SubStreet AS Add2,
					B.Street AS Add3,
					B.SubLocality AS Add4,
					B.Locality AS Add5,
					B.Town AS Add6,
					B.Region AS Add7,
					B.PostCode AS Add8,
					'' AS Add9,
					B.Country AS CTRY,
					B.EmailAddress,
					B.DealerName AS Dealer,
					B.VersionCode AS sno,
					B.CountryID AS ccode,
					B.ModelRequirementID AS modelcode,
					B.LanguageID AS lang,
					B.ManufacturerPartyID AS manuf,
					B.GenderID AS gender,
					B.QuestionnaireVersion AS qver,
					'' AS blank,
					B.EventTypeID AS etype,
					1 AS reminder,
					SelectionOutput.udfGetWeekNumber(GETDATE()) AS [week],
					0 AS test,
					0 AS SampleFlag,			-- V1.19
					'' AS SalesServiceFile,
					B.DealerCode,
					B.EventDate,
					B.LandPhone,
					B.WorkPhone,
					B.MobilePhone,
					B.PartyID,
					B.GDDDealerCode,			-- V1.3
					B.ReportingDealerPartyID,	-- V1.3
					B.VariantID,				-- V1.3
					B.ModelVariant,				-- V1.3
					B.BilingualFlag,			-- V1.23
					B.LanguageIDBilingual,		-- V1.23
					B.SalutationBilingual,		-- V1.23	
					B.FirstName					-- V1.24
				FROM SelectionOutput.Base B
					LEFT JOIN Blacklist BL ON BL.PartyID = B.PartyID 
												AND BL.ContactNumber = B.MobilePhone
					LEFT JOIN Reoutput RO ON RO.CaseID = B.CaseID
				WHERE ISNULL(B.MobilePhone, '') <> ''						-- V1.5 
					AND BL.PartyID IS NULL
					AND RO.CaseID IS NULL

				
				-- NOW GET THE DATA WITHOUT VALID SMS BUT WITH VALID EMAILS.  
				;WITH Blacklist AS 
				(
					SELECT DISTINCT 
						PCM.PartyID, 
						EA.EmailAddress
					FROM SelectionOutput.Base B
						INNER JOIN ContactMechanism.PartyContactMechanisms PCM ON PCM.PartyID = B.PartyID
						INNER JOIN ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = PCM.ContactMechanismID
						INNER JOIN ContactMechanism.BlacklistContactMechanisms BCM ON BCM.ContactMechanismID = PCM.ContactMechanismID
						INNER JOIN ContactMechanism.BlacklistStrings CMBS ON CMBS.BlacklistStringID = BCM.BlacklistStringID
						INNER JOIN ContactMechanism.BlacklistTypes CMBT ON CMBS.BlacklistTypeID = CMBT.BlacklistTypeID
																		AND ISNULL(CMBT.AFRLFilter, 0) = ISNULL(@ValidateAFRLCodes, 0)  -- V1.9 - ensure AFRL filtering is applied
				), Reoutput AS 
				(
					SELECT DISTINCT 
						CCMO.CaseID
					FROM [Event].CaseContactMechanismOutcomes CCMO
						INNER JOIN ContactMechanism.OutcomeCodes OC ON OC.OutcomeCode = CCMO.OutcomeCode
					WHERE OC.CausesReOutput = 1
						AND OC.OutcomeCodeTypeID = (	SELECT OutcomeCodeTypeID 
														FROM ContactMechanism.OutcomeCodeTypes 
														WHERE OutcomeCodeType = 'Online') -- EMAIL
				)
				INSERT INTO SelectionOutput.Email
				(
					[Password],
					[ID],
					FullModel,
					Model,
					sType,
					CarReg,
					Title,
					Initial,
					Surname,
					Fullname,
					DearName,
					CoName,
					Add1,
					Add2,
					Add3,
					Add4,
					Add5,
					Add6,
					Add7,
					Add8,
					Add9,
					CTRY,
					EmailAddress,
					Dealer,
					sno,
					ccode,
					modelcode,
					lang,
					manuf,
					gender,
					qver,
					blank,
					etype,
					reminder,
					[week],
					test,
					SampleFlag,
					SalesServiceFile,
					DealerCode,
					VIN,
					EventDate,
					LandPhone,
					WorkPhone,
					MobilePhone,
					PartyID,
					GDDDealerCode,			-- V1.3
					ReportingDealerPartyID, -- V1.3
					VariantID,				-- V1.3
					ModelVariant,			-- V1.3
					BilingualFlag,			-- V1.23	
					langBilingual,			-- V1.23
					DearNameBilingual		-- V1.23					
				)
				SELECT DISTINCT
					B.SelectionOutputPassword AS [Password],
					B.CaseID AS [ID],
					B.ModelDescription AS FullModel,
					B.ModelDescription AS Model,
					B.Manufacturer AS sType,
					B.RegistrationNumber AS CarReg,
					B.Title,
					B.FirstName AS Initial,
					B.LastName AS Surname,
					B.Addressee AS Fullname,
					B.Salutation AS DearName,
					B.OrganisationName AS CoName,
					B.BuildingName AS Add1,
					B.SubStreet AS Add2,
					B.Street AS Add3,
					B.SubLocality AS Add4,
					B.Locality AS Add5,
					B.Town AS Add6,
					B.Region AS Add7,
					B.PostCode AS Add8,
					'' AS Add9,
					B.Country AS CTRY,
					B.EmailAddress,
					B.DealerName AS Dealer,
					B.VersionCode AS sno,
					B.CountryID AS ccode,
					B.ModelRequirementID AS modelcode,
					B.LanguageID AS lang,
					B.ManufacturerPartyID AS manuf,
					B.GenderID AS gender,
					B.QuestionnaireVersion AS qver,
					'' AS blank,
					B.EventTypeID AS etype,
					1 AS reminder,
					SelectionOutput.udfGetWeekNumber(GETDATE()) AS [week],
					0 AS test,
					0 AS SampleFlag,			 -- V1.19
					'' AS SalesServiceFile,
					B.DealerCode,
					B.VIN,
					B.EventDate,
					B.LandPhone,
					B.WorkPhone,
					B.MobilePhone,
					B.PartyID,
					B.GDDDealerCode,			-- V1.3
					B.ReportingDealerPartyID,	-- V1.3
					B.VariantID,				-- V1.3
					B.ModelVariant,				-- V1.3
					B.BilingualFlag,			-- V1.23
					B.LanguageIDBilingual,		-- V1.23
					B.SalutationBilingual		-- V1.23	
				FROM SelectionOutput.Base B
					LEFT JOIN SelectionOutput.SMS E ON E.ID = B.CaseID
					LEFT JOIN Blacklist BL ON BL.PartyID = B.PartyID 
											AND BL.EmailAddress = B.EmailAddress
					LEFT JOIN Reoutput RO ON RO.CaseID = B.CaseID
				WHERE ISNULL(B.EmailAddressContactMechanismID, 0) > 0 
					AND BL.PartyID IS NULL
					AND RO.CaseID IS NULL
					AND E.ID IS NULL
	
			END 


			--------------------------------------------------------------------------------
			-- MIXED EMAIL AND SMS   (Use Email in preference over SMS)	-- V1.13 New ContactMethodologyType
			--------------------------------------------------------------------------------
			IF @ContactMethodologyTypeID = (	SELECT ContactMethodologyTypeID 
												FROM SelectionOutput.ContactMethodologyTypes 
												WHERE ContactMethodologyType = 'Mixed (Email & SMS)')	-- V1.13
			BEGIN	
			
				-- WE'RE IN A MIXED METHODOLOGY SO WE'RE NOT FORCING RECORDS TO HAVE AN EMAIL ADDRESS.
				-- WE JUST WANT TO GET ALL OF THE SELECTED RECORDS THAT DO HAVE A VALID EMAIL AND EMAIL THE INVITATION.
				
				-- GET THE DATA WITH EMAIL FIRST OF ALL
				;WITH Blacklist AS 
				(
					SELECT DISTINCT 
						PCM.PartyID, 
						EA.EmailAddress
					FROM SelectionOutput.Base B
						INNER JOIN ContactMechanism.PartyContactMechanisms PCM ON PCM.PartyID = B.PartyID
						INNER JOIN ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = PCM.ContactMechanismID
						INNER JOIN ContactMechanism.BlacklistContactMechanisms BCM ON BCM.ContactMechanismID = PCM.ContactMechanismID
						INNER JOIN ContactMechanism.BlacklistStrings CMBS ON CMBS.BlacklistStringID = BCM.BlacklistStringID
						INNER JOIN ContactMechanism.BlacklistTypes CMBT ON CMBS.BlacklistTypeID = CMBT.BlacklistTypeID
																		AND ISNULL(CMBT.AFRLFilter, 0) = ISNULL(@ValidateAFRLCodes, 0)  -- V1.9 - ensure AFRL filtering is applied
				), Reoutput AS 
				(
					SELECT DISTINCT 
						CCMO.CaseID
					FROM [Event].CaseContactMechanismOutcomes CCMO
						INNER JOIN ContactMechanism.OutcomeCodes OC ON OC.OutcomeCode = CCMO.OutcomeCode
					WHERE OC.CausesReOutput = 1
						AND OC.OutcomeCodeTypeID = (	SELECT OutcomeCodeTypeID 
														FROM ContactMechanism.OutcomeCodeTypes 
														WHERE OutcomeCodeType = 'Online') -- EMAIL
				)
				INSERT INTO SelectionOutput.Email
				(
					[Password],
					[ID],
					FullModel,
					Model,
					sType,
					CarReg,
					Title,
					Initial,
					Surname,
					Fullname,
					DearName,
					CoName,
					Add1,
					Add2,
					Add3,
					Add4,
					Add5,
					Add6,
					Add7,
					Add8,
					Add9,
					CTRY,
					EmailAddress,
					Dealer,
					sno,
					ccode,
					modelcode,
					lang,
					manuf,
					gender,
					qver,
					blank,
					etype,
					reminder,
					[week],
					test,
					SampleFlag,
					SalesServiceFile,
					DealerCode,
					VIN,
					EventDate,
					LandPhone,
					WorkPhone,
					MobilePhone,
					PartyID,
					GDDDealerCode,			-- V1.3
					ReportingDealerPartyID, -- V1.3
					VariantID,				-- V1.3
					ModelVariant,			-- V1.3
					BilingualFlag,			-- V1.23	
					langBilingual,			-- V1.23
					DearNameBilingual		-- V1.23					
				)
				SELECT DISTINCT
					B.SelectionOutputPassword AS [Password],
					B.CaseID AS [ID],
					B.ModelDescription AS FullModel,
					B.ModelDescription AS Model,
					B.Manufacturer AS sType,
					B.RegistrationNumber AS CarReg,
					B.Title,
					B.FirstName AS Initial,
					B.LastName AS Surname,
					B.Addressee AS Fullname,
					B.Salutation AS DearName,
					B.OrganisationName AS CoName,
					B.BuildingName AS Add1,
					B.SubStreet AS Add2,
					B.Street AS Add3,
					B.SubLocality AS Add4,
					B.Locality AS Add5,
					B.Town AS Add6,
					B.Region AS Add7,
					B.PostCode AS Add8,
					'' AS Add9,
					B.Country AS CTRY,
					B.EmailAddress,
					B.DealerName AS Dealer,
					B.VersionCode AS sno,
					B.CountryID AS ccode,
					B.ModelRequirementID AS modelcode,
					B.LanguageID AS lang,
					B.ManufacturerPartyID AS manuf,
					B.GenderID AS gender,
					B.QuestionnaireVersion AS qver,
					'' AS blank,
					B.EventTypeID AS etype,
					1 AS reminder,
					SelectionOutput.udfGetWeekNumber(GETDATE()) AS [week],
					0 AS test,
					0 AS SampleFlag,			-- V1.19
					'' AS SalesServiceFile,
					B.DealerCode,
					B.VIN,
					B.EventDate,
					B.LandPhone,
					B.WorkPhone,
					B.MobilePhone,
					B.PartyID,
					B.GDDDealerCode,			-- V1.3
					B.ReportingDealerPartyID,	-- V1.3
					B.VariantID,				-- V1.3
					B.ModelVariant,				-- V1.3
					B.BilingualFlag,			-- V1.23
					B.LanguageIDBilingual,		-- V1.23
					B.SalutationBilingual		-- V1.23	
				FROM SelectionOutput.Base B
					LEFT JOIN Blacklist BL ON BL.PartyID = B.PartyID 
											AND BL.EmailAddress = B.EmailAddress
					LEFT JOIN Reoutput RO ON RO.CaseID = B.CaseID
				WHERE ISNULL(B.EmailAddressContactMechanismID, 0) > 0 
					AND BL.PartyID IS NULL
					AND RO.CaseID IS NULL
	
	
				-- NOW GET THE DATA WITHOUT VALID EMAILS BUT WITH VALID SMS.  
				;WITH Blacklist AS 
				(
					SELECT DISTINCT 
						PCM.PartyID, 
						TN.ContactNumber
					FROM SelectionOutput.Base B
						INNER JOIN ContactMechanism.PartyContactMechanisms PCM ON PCM.PartyID = B.PartyID
						INNER JOIN ContactMechanism.TelephoneNumbers TN ON TN.ContactMechanismID = PCM.ContactMechanismID
						INNER JOIN ContactMechanism.BlacklistContactMechanisms BCM ON BCM.ContactMechanismID = PCM.ContactMechanismID
						--INNER JOIN ContactMechanism.BlacklistStrings CMBS ON CMBS.BlacklistStringID = BCM.BlacklistStringID
						--INNER JOIN ContactMechanism.BlacklistTypes CMBT ON CMBS.BlacklistTypeID = CMBT.BlacklistTypeID
				), Reoutput AS 
				(
					SELECT DISTINCT 
						CCMO.CaseID
					FROM [Event].CaseContactMechanismOutcomes CCMO
						INNER JOIN ContactMechanism.OutcomeCodes OC ON OC.OutcomeCode = CCMO.OutcomeCode
					WHERE OC.CausesReOutput = 1
						AND OC.OutcomeCodeTypeID = (	SELECT OutcomeCodeTypeID 
														FROM ContactMechanism.OutcomeCodeTypes 
														WHERE OutcomeCodeType = 'SMS')
				)
				INSERT INTO SelectionOutput.SMS
				(
					[Password],
					[ID],
					FullModel,
					Model,
					VIN,
					sType,
					CarReg,
					Title,
					Initial,
					Surname,
					Fullname,
					DearName,
					CoName,
					Add1,
					Add2,
					Add3,
					Add4,
					Add5,
					Add6,
					Add7,
					Add8,
					Add9,
					CTRY,
					EmailAddress,
					Dealer,
					sno,
					ccode,
					modelcode,
					lang,
					manuf,
					gender,
					qver,
					blank,
					etype,
					reminder,
					[week],
					test,
					SampleFlag,
					SalesServiceFile,
					DealerCode,
					EventDate,
					LandPhone,
					WorkPhone,
					MobilePhone,
					PartyID,
					GDDDealerCode,			-- V1.3
					ReportingDealerPartyID, -- V1.3
					VariantID,				-- V1.3
					ModelVariant,			-- V1.3
					BilingualFlag,			-- V1.23	
					langBilingual,			-- V1.23
					DearNameBilingual,		-- V1.23
					FirstName				-- V1.24					
				)
				SELECT DISTINCT
					B.SelectionOutputPassword AS [Password],
					B.CaseID AS [ID],
					B.ModelDescription AS FullModel,
					B.ModelDescription AS Model,
					B.VIN,
					B.Manufacturer AS sType,
					B.RegistrationNumber AS CarReg,
					B.Title,
					B.FirstName AS Initial,
					B.LastName AS Surname,
					B.Addressee AS Fullname,
					B.Salutation AS DearName,
					B.OrganisationName AS CoName,
					B.BuildingName AS Add1,
					B.SubStreet AS Add2,
					B.Street AS Add3,
					B.SubLocality AS Add4,
					B.Locality AS Add5,
					B.Town AS Add6,
					B.Region AS Add7,
					B.PostCode AS Add8,
					'' AS Add9,
					B.Country AS CTRY,
					B.EmailAddress,
					B.DealerName AS Dealer,
					B.VersionCode AS sno,
					B.CountryID AS ccode,
					B.ModelRequirementID AS modelcode,
					B.LanguageID AS lang,
					B.ManufacturerPartyID AS manuf,
					B.GenderID AS gender,
					B.QuestionnaireVersion AS qver,
					'' AS blank,
					B.EventTypeID AS etype,
					1 AS reminder,
					SelectionOutput.udfGetWeekNumber(GETDATE()) AS [week],
					0 AS test,
					0 AS SampleFlag,			-- V1.19
					'' AS SalesServiceFile,
					B.DealerCode,
					B.EventDate,
					B.LandPhone,
					B.WorkPhone,
					B.MobilePhone,
					B.PartyID,
					B.GDDDealerCode,			-- V1.3
					B.ReportingDealerPartyID,	-- V1.3
					B.VariantID,				-- V1.3
					B.ModelVariant,				-- V1.3
					B.BilingualFlag,			-- V1.23
					B.LanguageIDBilingual,		-- V1.23
					B.SalutationBilingual,		-- V1.23	
					B.FirstName					-- V1.24

				FROM SelectionOutput.Base B
					LEFT JOIN SelectionOutput.Email E ON E.ID = B.CaseID
					LEFT JOIN Blacklist BL ON BL.PartyID = B.PartyID 
											AND BL.ContactNumber = B.MobilePhone
					LEFT JOIN Reoutput RO ON RO.CaseID = B.CaseID
				WHERE ISNULL(B.MobilePhone, '') <> ''						-- V1.5 
					AND BL.PartyID IS NULL
					AND RO.CaseID IS NULL
					AND E.ID IS NULL

			END 
		
	
			--------------------------------------------------------------------------------
			-- MIXED EMAIL AND TELEPHONE  (Email in preference to telephone)
			--------------------------------------------------------------------------------
			IF @ContactMethodologyTypeID = (	SELECT ContactMethodologyTypeID 
												FROM SelectionOutput.ContactMethodologyTypes 
												WHERE ContactMethodologyType = 'Mixed (email & CATI)')
			BEGIN	
			
				-- WE'RE IN A MIXED METHODOLOGY SO WE'RE NOT FORCING RECORDS TO HAVE AN EMAIL ADDRESS.
				-- WE JUST WANT TO GET ALL OF THE SELECTED RECORDS THAT DO HAVE A VALID EMAIL AND EMAIL THE INVITATION.
				
				-- GET THE DATA WITH EMAILS FIRST OF ALL
				;WITH Blacklist AS 
				(
					SELECT DISTINCT 
						PCM.PartyID, 
						EA.EmailAddress
					FROM ContactMechanism.PartyContactMechanisms PCM
						INNER JOIN ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = PCM.ContactMechanismID
						INNER JOIN ContactMechanism.BlacklistContactMechanisms BCM ON BCM.ContactMechanismID = PCM.ContactMechanismID
						INNER JOIN ContactMechanism.BlacklistStrings CMBS ON CMBS.BlacklistStringID = BCM.BlacklistStringID
						INNER JOIN ContactMechanism.BlacklistTypes CMBT ON CMBS.BlacklistTypeID = CMBT.BlacklistTypeID
																		AND ISNULL(CMBT.AFRLFilter, 0) = ISNULL(@ValidateAFRLCodes, 0)  -- V1.9 - ensure AFRL filtering is applied
				), Reoutput AS 
				(
					SELECT DISTINCT 
						CCMO.CaseID
					FROM [Event].CaseContactMechanismOutcomes CCMO
						INNER JOIN ContactMechanism.OutcomeCodes OC ON OC.OutcomeCode = CCMO.OutcomeCode
					WHERE OC.CausesReOutput = 1
						AND OC.OutcomeCodeTypeID = (	SELECT OutcomeCodeTypeID 
														FROM ContactMechanism.OutcomeCodeTypes 
														WHERE OutcomeCodeType = 'Online') -- EMAIL
				)
				INSERT INTO SelectionOutput.Email
				(
					[Password],
					[ID],
					FullModel,
					Model,
					VIN,
					sType,
					CarReg,
					Title,
					Initial,
					Surname,
					Fullname,
					DearName,
					CoName,
					Add1,
					Add2,
					Add3,
					Add4,
					Add5,
					Add6,
					Add7,
					Add8,
					Add9,
					CTRY,
					EmailAddress,
					Dealer,
					sno,
					ccode,
					modelcode,
					lang,
					manuf,
					gender,
					qver,
					blank,
					etype,
					reminder,
					[week],
					test,
					SampleFlag,
					SalesServiceFile,
					DealerCode,
					EventDate,
					LandPhone,
					WorkPhone,
					MobilePhone,
					PartyID,
					GDDDealerCode,			-- V1.3
					ReportingDealerPartyID, -- V1.3
					VariantID,				-- V1.3
					ModelVariant,			-- V1.3
					BilingualFlag,			-- V1.23	
					langBilingual,			-- V1.23
					DearNameBilingual		-- V1.23					
				)
				SELECT DISTINCT
					B.SelectionOutputPassword AS [Password],
					B.CaseID AS [ID],
					B.ModelDescription AS FullModel,
					B.ModelDescription AS Model,
					B.VIN,
					B.Manufacturer AS sType,
					B.RegistrationNumber AS CarReg,
					B.Title,
					B.FirstName AS Initial,
					B.LastName AS Surname,
					B.Addressee AS Fullname,
					B.Salutation AS DearName,
					B.OrganisationName AS CoName,
					B.BuildingName AS Add1,
					B.SubStreet AS Add2,
					B.Street AS Add3,
					B.SubLocality AS Add4,
					B.Locality AS Add5,
					B.Town AS Add6,
					B.Region AS Add7,
					B.PostCode AS Add8,
					'' AS Add9,
					B.Country AS CTRY,
					B.EmailAddress,
					B.DealerName AS Dealer,
					B.VersionCode AS sno,
					B.CountryID AS ccode,
					B.ModelRequirementID AS modelcode,
					B.LanguageID AS lang,
					B.ManufacturerPartyID AS manuf,
					B.GenderID AS gender,
					B.QuestionnaireVersion AS qver,
					'' AS blank,
					B.EventTypeID AS etype,
					1 AS reminder,
					SelectionOutput.udfGetWeekNumber(GETDATE()) AS [week],
					0 AS test,
					0 AS SampleFlag,			-- V1.19
					'' AS SalesServiceFile,
					B.DealerCode,
					B.EventDate,
					B.LandPhone,
					B.WorkPhone,
					B.MobilePhone,
					B.PartyID,
					B.GDDDealerCode,			-- V1.3
					B.ReportingDealerPartyID,	-- V1.3
					B.VariantID,				-- V1.3
					B.ModelVariant,				-- V1.3
					B.BilingualFlag,			-- V1.23
					B.LanguageIDBilingual,		-- V1.23
					B.SalutationBilingual		-- V1.23	
				FROM SelectionOutput.Base B
					LEFT JOIN Blacklist BL ON BL.PartyID = B.PartyID 
											AND BL.EmailAddress = B.EmailAddress
					LEFT JOIN Reoutput RO ON RO.CaseID = B.CaseID
				WHERE ISNULL(B.EmailAddressContactMechanismID, 0) > 0 
					AND BL.PartyID IS NULL
					AND RO.CaseID IS NULL

				
				-- NOW GET THE DATA WITHOUT VALID EMAILS BUT WITH VALID TELEPHONE NUMBERS.  
				INSERT INTO SelectionOutput.CATI
				(
					VIN,
					DealerCode,
					ModelDesc,
					CoName,
					Add1,
					Add2,
					Add3,
					Add4,
					Add5,
					LandPhone,
					WorkPhone,
					MobilePhone,
					PartyID,
					CaseID,
					DateOutput,
					JLR,
					EventTypeID,
					RegNumber,
					RegDate,
					LocalName,
					EventDate,
					SelectionOutputPassword,
					GDDDealerCode,			-- V1.3
					ReportingDealerPartyID, -- V1.3
					VariantID,				-- V1.3
					ModelVariant,			-- V1.3
					[Queue],				-- V1.11
					AssignedMode,			-- V1.11
					RequiresManualDial,		-- V1.11
					CallRecordingsCount,	-- V1.11
					TimeZone,				-- V1.11
					CallOutcome,			-- V1.11
					PhoneNumber,			-- V1.11
					PhoneSource,			-- V1.11
					[Language],				-- V1.11
					ExpirationTime,			-- V1.11
					HomePhoneNumber,		-- V1.11
					WorkPhoneNumber,		-- V1.11
					MobilePhoneNumber		-- V1.11
				)
				SELECT
					B.VIN,
					B.DealerCode,
					B.ModelDesc,
					B.CoName,
					B.Add1,
					B.Add2,
					B.Add3,
					B.Add4,
					B.Add5,
					B.LandPhone,
					B.WorkPhone,
					B.MobilePhone,
					B.PartyID,
					B.CaseID,
					B.DateOutput,
					B.JLR,
					B.EventTypeID,
					B.RegNumber,
					B.RegDate,
					B.LocalName,
					B.EventDate,
					B.SelectionOutputPassword,
					B.GDDDealerCode,			-- V1.3
					B.ReportingDealerPartyID,	-- V1.3
					B.VariantID,				-- V1.3
					B.ModelVariant,				-- V1.3
					'FRESH' AS [Queue],
					'Phone' AS AssignedMode,
					1 AS RequiresManualDial,
					1 AS CallRecordingsCount,
					ISNULL(CT.TimeZoneID, 0) AS TimeZone,
					'Undialled' AS CallOutcome, 
					COALESCE (	NULLIF(SelectionOutput.udfFormatTelNoForDimensions(B.MobilePhone, CD.CountryID), ''),
								NULLIF(SelectionOutput.udfFormatTelNoForDimensions(B.LandPhone, CD.CountryID), ''),
								NULLIF(SelectionOutput.udfFormatTelNoForDimensions(B.WorkPhone, CD.CountryID), ''),
								'') AS PhoneNumber,
					CASE	WHEN ISNULL(B.MobilePhone, '') <> '' THEN 'MobilePhoneNumber'
							WHEN ISNULL(B.LandPhone, '') <> '' THEN 'HomePhoneNumber'
							WHEN ISNULL(B.WorkPhone, '') <> '' THEN 'WorkPhoneNumber'
							ELSE '' END AS PhoneSource,
					CASE	WHEN LV.LanguageID IS NULL THEN ISNULL(DL.LanguageCode, '')
							ELSE ISNULL(DL2.LanguageCode, '') END AS [Language], 
					--EXPIRES AT MIDNIGHT
					CONVERT (DATETIME, CONVERT(VARCHAR(10), DATEADD(dd, BMQ.NumDaysToExpireOnlineQuestionnaire, @dtCATI), 120) + '  23:59:59') AS ExpirationTime,																																													-- V1.22
					SelectionOutput.udfFormatTelNoForDimensions(B.LandPhone, CD.CountryID) AS HomePhoneNumber,
					SelectionOutput.udfFormatTelNoForDimensions(B.WorkPhone, CD.CountryID) AS WorkPhoneNumber,
					SelectionOutput.udfFormatTelNoForDimensions(B.MobilePhone, CD.CountryID) AS MobilePhoneNumber
				FROM SelectionOutput.vwCATIBase B
					LEFT JOIN SelectionOutput.Email E ON E.ID = B.CaseID
					INNER JOIN Meta.Casedetails CD ON B.CaseID = CD.CaseID
					INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata	MD	ON CD.QuestionnaireRequirementID = MD.QuestionnaireRequirementID
					INNER JOIN dbo.BrandMarketQuestionnaireMetadata BMQ	ON MD.BMQID	= BMQ.BMQID
					LEFT JOIN Dimensions.CountryAndTimezone CT ON CD.CountryID = CT.CountryID
					LEFT JOIN Dimensions.DimensionsLanguage DL ON CD.LanguageID = DL.LanguageID
					LEFT JOIN Dimensions.LanguageVariation LV ON CD.LanguageID = LV.LanguageID 
																AND CD.CountryID = LV.CountryID
					LEFT JOIN Dimensions.DimensionsLanguage DL2 ON LV.DimensionsLanguageID = DL2.DimensionsLanguageID			
				WHERE E.ID IS NULL
			END		
			
			
			--------------------------------------------------------------------------------
			-- MIXED TELEPHONE AND EMAIL  (Telephone in preference to Email)    -- V1.12
			--------------------------------------------------------------------------------
			IF @ContactMethodologyTypeID = (	SELECT ContactMethodologyTypeID 
												FROM SelectionOutput.ContactMethodologyTypes 
												WHERE ContactMethodologyType = 'Mixed (CATI & Email)')
			BEGIN	
			
				-- WE'RE IN A MIXED METHODOLOGY SO WE'RE NOT FORCING RECORDS TO HAVE AN TELEPHONE NUMBERS.
				-- WE JUST WANT TO GET ALL OF THE SELECTED RECORDS THAT DO HAVE A VALID TELEPHONE AND USE CATI FOR THE INVITATION.
				
				INSERT INTO SelectionOutput.CATI
				(
					VIN,
					DealerCode,
					ModelDesc,
					CoName,
					Add1,
					Add2,
					Add3,
					Add4,
					Add5,
					LandPhone,
					WorkPhone,
					MobilePhone,
					PartyID,
					CaseID,
					DateOutput,
					JLR,
					EventTypeID,
					RegNumber,
					RegDate,
					LocalName,
					EventDate,
					SelectionOutputPassword,
					GDDDealerCode,				-- V1.3
					ReportingDealerPartyID,		-- V1.3
					VariantID,					-- V1.3
					ModelVariant,				-- V1.3
					[Queue],					-- V1.11
					AssignedMode,				-- V1.11
					RequiresManualDial,			-- V1.11
					CallRecordingsCount,		-- V1.11
					TimeZone,					-- V1.11
					CallOutcome,				-- V1.11
					PhoneNumber,				-- V1.11
					PhoneSource,				-- V1.11
					[Language],					-- V1.11
					ExpirationTime,				-- V1.11
					HomePhoneNumber,			-- V1.11
					WorkPhoneNumber,			-- V1.11
					MobilePhoneNumber			-- V1.11
				)
				SELECT
					B.VIN,
					B.DealerCode,
					B.ModelDesc,
					B.CoName,
					B.Add1,
					B.Add2,
					B.Add3,
					B.Add4,
					B.Add5,
					B.LandPhone,
					B.WorkPhone,
					B.MobilePhone,
					B.PartyID,
					B.CaseID,
					B.DateOutput,
					B.JLR,
					B.EventTypeID,
					B.RegNumber,
					B.RegDate,
					B.LocalName,
					B.EventDate,
					B.SelectionOutputPassword,
					B.GDDDealerCode,			-- V1.3
					B.ReportingDealerPartyID,	-- V1.3
					B.VariantID,				-- V1.3
					B.ModelVariant,				-- V1.3
					'FRESH' AS [Queue],
					'Phone' AS AssignedMode,
					1 AS RequiresManualDial,
					1 AS CallRecordingsCount,
					ISNULL(CT.TimeZoneID, 0) AS TimeZone,
					'Undialled' AS CallOutcome, 
					COALESCE (	NULLIF(SelectionOutput.udfFormatTelNoForDimensions(B.MobilePhone, CD.CountryID), ''),
								NULLIF(SelectionOutput.udfFormatTelNoForDimensions(B.LandPhone, CD.CountryID), ''),
								NULLIF(SelectionOutput.udfFormatTelNoForDimensions(B.WorkPhone, CD.CountryID), ''),
								'') AS PhoneNumber,
					CASE	WHEN ISNULL(B.MobilePhone, '') <> '' THEN 'MobilePhoneNumber'
							WHEN ISNULL(B.LandPhone, '') <> '' THEN 'HomePhoneNumber'
							WHEN ISNULL(B.WorkPhone, '') <> '' THEN 'WorkPhoneNumber'
							ELSE ''	END AS PhoneSource,
					CASE	WHEN LV.LanguageID IS NULL THEN ISNULL(DL.LanguageCode, '')
							ELSE ISNULL(DL2.LanguageCode, '') END AS [Language], 
					--EXPIRES AT MIDNIGHT																																													-- V1.22
					CONVERT (DATETIME, CONVERT(VARCHAR(10), DATEADD(dd, BMQ.NumDaysToExpireOnlineQuestionnaire, @dtCATI), 120) + '  23:59:59') AS ExpirationTime,		
					SelectionOutput.udfFormatTelNoForDimensions(B.LandPhone, CD.CountryID) AS HomePhoneNumber,
					SelectionOutput.udfFormatTelNoForDimensions(B.WorkPhone, CD.CountryID) AS WorkPhoneNumber,
					SelectionOutput.udfFormatTelNoForDimensions(B.MobilePhone, CD.CountryID) AS MobilePhoneNumber
				FROM SelectionOutput.vwCATIBase B
					LEFT JOIN SelectionOutput.Email E ON E.ID = B.CaseID
					INNER JOIN Meta.Casedetails CD ON B.CaseID = CD.CaseID
					INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata	MD ON CD.QuestionnaireRequirementID = MD.QuestionnaireRequirementID
					INNER JOIN dbo.BrandMarketQuestionnaireMetadata BMQ ON MD.BMQID = BMQ.BMQID
					LEFT JOIN Dimensions.CountryAndTimezone CT ON CD.CountryID = CT.CountryID
					LEFT JOIN Dimensions.DimensionsLanguage DL ON CD.LanguageID = DL.LanguageID
					LEFT JOIN Dimensions.LanguageVariation LV ON CD.LanguageID = LV.LanguageID 
																AND CD.CountryID = LV.CountryID
					LEFT JOIN Dimensions.DimensionsLanguage DL2 ON LV.DimensionsLanguageID = DL2.DimensionsLanguageID		
				WHERE E.ID IS NULL
					AND (B.MobilePhone IS NOT NULL 
							OR B.LandPhone IS NOT NULL 
							OR B.WorkPhone IS NOT NULL)


				-- NOW OUTPUT THE REMAINING RECORDS AS EMAIL	-v1.12
				;WITH Blacklist AS 
				(
					SELECT DISTINCT PCM.PartyID, EA.EmailAddress
					FROM ContactMechanism.PartyContactMechanisms PCM
						INNER JOIN ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = PCM.ContactMechanismID
						INNER JOIN ContactMechanism.BlacklistContactMechanisms BCM ON BCM.ContactMechanismID = PCM.ContactMechanismID
						INNER JOIN ContactMechanism.BlacklistStrings CMBS ON CMBS.BlacklistStringID = BCM.BlacklistStringID
						INNER JOIN ContactMechanism.BlacklistTypes CMBT ON CMBS.BlacklistTypeID = CMBT.BlacklistTypeID
																		AND ISNULL(CMBT.AFRLFilter, 0) = ISNULL(@ValidateAFRLCodes, 0)  -- V1.9 - ensure AFRL filtering is applied
				), Reoutput AS 
				(
					SELECT DISTINCT CCMO.CaseID
					FROM [Event].CaseContactMechanismOutcomes CCMO
						INNER JOIN ContactMechanism.OutcomeCodes OC ON OC.OutcomeCode = CCMO.OutcomeCode
					WHERE OC.CausesReOutput = 1
						AND OC.OutcomeCodeTypeID = (	SELECT OutcomeCodeTypeID 
														FROM ContactMechanism.OutcomeCodeTypes 
														WHERE OutcomeCodeType = 'Online') -- EMAIL
				)
				INSERT INTO SelectionOutput.Email
				(
					[Password],
					[ID],
					FullModel,
					Model,
					VIN,
					sType,
					CarReg,
					Title,
					Initial,
					Surname,
					Fullname,
					DearName,
					CoName,
					Add1,
					Add2,
					Add3,
					Add4,
					Add5,
					Add6,
					Add7,
					Add8,
					Add9,
					CTRY,
					EmailAddress,
					Dealer,
					sno,
					ccode,
					modelcode,
					lang,
					manuf,
					gender,
					qver,
					blank,
					etype,
					reminder,
					[week],
					test,
					SampleFlag,
					SalesServiceFile,
					DealerCode,
					EventDate,
					LandPhone,
					WorkPhone,
					MobilePhone,
					PartyID,
					GDDDealerCode,			-- V1.3
					ReportingDealerPartyID, -- V1.3
					VariantID,				-- V1.3
					ModelVariant,			-- V1.3
					BilingualFlag,			-- V1.23	
					langBilingual,			-- V1.23
					DearNameBilingual		-- V1.23					
				)
				SELECT DISTINCT
					B.SelectionOutputPassword AS [Password],
					B.CaseID AS [ID],
					B.ModelDescription AS FullModel,
					B.ModelDescription AS Model,
					B.VIN,
					B.Manufacturer AS sType,
					B.RegistrationNumber AS CarReg,
					B.Title,
					B.FirstName AS Initial,
					B.LastName AS Surname,
					B.Addressee AS Fullname,
					B.Salutation AS DearName,
					B.OrganisationName AS CoName,
					B.BuildingName AS Add1,
					B.SubStreet AS Add2,
					B.Street AS Add3,
					B.SubLocality AS Add4,
					B.Locality AS Add5,
					B.Town AS Add6,
					B.Region AS Add7,
					B.PostCode AS Add8,
					'' AS Add9,
					B.Country AS CTRY,
					B.EmailAddress,
					B.DealerName AS Dealer,
					B.VersionCode AS sno,
					B.CountryID AS ccode,
					B.ModelRequirementID AS modelcode,
					B.LanguageID AS lang,
					B.ManufacturerPartyID AS manuf,
					B.GenderID AS gender,
					B.QuestionnaireVersion AS qver,
					'' AS blank,
					B.EventTypeID AS etype,
					1 AS reminder,
					SelectionOutput.udfGetWeekNumber(GETDATE()) AS [week],
					0 AS test,
					0 AS SampleFlag,			-- V1.19
					'' AS SalesServiceFile,
					B.DealerCode,
					B.EventDate,
					B.LandPhone,
					B.WorkPhone,
					B.MobilePhone,
					B.PartyID,
					B.GDDDealerCode,			-- V1.3
					B.ReportingDealerPartyID,	-- V1.3
					B.VariantID,				-- V1.3
					B.ModelVariant,				-- V1.3
					B.BilingualFlag,			-- V1.23
					B.LanguageIDBilingual,		-- V1.23
					B.SalutationBilingual		-- V1.23	
				FROM SelectionOutput.Base B
					LEFT JOIN Blacklist BL ON BL.PartyID = B.PartyID 
											AND BL.EmailAddress = B.EmailAddress
					LEFT JOIN Reoutput RO ON RO.CaseID = B.CaseID
					LEFT JOIN SelectionOutput.CATI C ON C.CaseID = B.CaseID
				WHERE ISNULL(B.EmailAddressContactMechanismID, 0) > 0 
					AND BL.PartyID IS NULL
					AND RO.CaseID IS NULL
					AND C.CaseID IS NULL		--  Do not include where already selected for CATI 
				
			END
			
		END


		--------------------------------------------------------------------------------
		-- GET ANY REMAINING CASEIDS THAT WE HAVEN'T ALREADY LOADED (INCLUDING NON OUTPUT)
		--------------------------------------------------------------------------------
		INSERT INTO SelectionOutput.NonOutput (CaseID, PartyID)
		SELECT B.CaseID, 
			B.PartyID
		FROM SelectionOutput.Base B
			LEFT JOIN (	SELECT DISTINCT CaseID
						FROM SelectionOutput.CATI
						UNION
						SELECT DISTINCT [ID] AS CaseID
						FROM SelectionOutput.Email
						UNION
						SELECT DISTINCT [ID] AS CaseID						-- V1.5
						FROM SelectionOutput.SMS
						UNION
						SELECT DISTINCT [ID] AS CaseID
						FROM SelectionOutput.Postal) C ON C.CaseID = B.CaseID
		WHERE C.CaseID IS NULL
		

		-- CLEAR DOWN SelectionOutput.Base
		DELETE FROM SelectionOutput.Base

		-- INCREMENT THE COUNTER
		SET @Counter = @Counter + 1
	
	END -- OF WHILE LOOP -----------------------------------------------------------
	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------
			

	
	--------------------------------------------------------------------------------
	-- GET THE RE OUTPUTTED CASES FROM SelectionOutput.ReOutputPostal
	--------------------------------------------------------------------------------
	INSERT INTO SelectionOutput.Postal
	(
		[Password], 
		ID, 
		FullModel, 
		Model, 
		sType, 
		CarReg, 
		Title, 
		Initial, 
		Surname, 
		Fullname, 
		DearName, 
		CoName, 
		Add1, 
		Add2, 
		Add3, 
		Add4, 
		Add5, 
		Add6, 
		Add7, 
		Add8, 
		Add9, 
		CTRY, 
		EmailAddress, 
		Dealer, 
		sno, 
		ccode, 
		modelcode, 
		lang, 
		manuf, 
		gender, 
		qver, 
		blank, 
		etype, 
		reminder, 
		week, 
		test, 
		SampleFlag, 
		SalesServiceFile ,
		DealerCode,
		VIN,
		EventDate,
		LandPhone,
		WorkPhone,
		MobilePhone,
		PartyID,
		GDDDealerCode,			-- V1.3
		ReportingDealerPartyID, -- V1.3
		VariantID,				-- V1.3
		ModelVariant,			-- V1.3
		BilingualFlag,			-- V1.23	
		langBilingual,			-- V1.23
		DearNameBilingual,		-- V1.23
		ReoutputIndicator		-- V1.26
	)
	SELECT
		RO.SelectionOutputPassword, 
		RO.ID, 
		RO.FullModel, 
		RO.Model, 
		RO.sType, 
		RO.CarReg, 
		RO.Title, 
		RO.Initial, 
		RO.Surname, 
		RO.Fullname, 
		RO.DearName, 
		RO.CoName, 
		RO.Add1, 
		RO.Add2, 
		RO.Add3, 
		RO.Add4, 
		RO.Add5, 
		RO.Add6, 
		RO.Add7, 
		RO.Add8, 
		RO.Add9, 
		RO.CTRY, 
		RO.EmailAddress, 
		RO.Dealer, 
		RO.sno, 
		RO.ccode, 
		RO.modelcode, 
		RO.lang, 
		RO.manuf, 
		RO.gender, 
		RO.qver, 
		RO.blank, 
		RO.etype, 
		RO.reminder, 
		RO.week, 
		RO.test, 
		RO.SampleFlag, 
		RO.SalesServiceFile,
		RO.DealerCode,
		RO.VIN,
		RO.EventDate,
		RO.LandPhone,
		RO.WorkPhone,
		RO.MobilePhone,
		RO.PartyID,
		RO.GDDDealerCode,			-- V1.3
		RO.ReportingDealerPartyID,	-- V1.3
		RO.VariantID,				-- V1.3
		RO.ModelVariant,			-- V1.3
		RO.BilingualFlag,			-- V1.23
		RO.langBilingual,			-- V1.23
		RO.DearNameBilingual,		-- V1.23
		1 AS ReoutputIndicator		-- V1.26
	FROM SelectionOutput.ReOutputPostal RO
	INNER JOIN (	SELECT DISTINCT 
						BMQID,
						Brand,
						ISOAlpha3,
						Questionnaire
					FROM dbo.vwBrandMarketQuestionnaireSampleMetadata) BMQ ON BMQ.BMQID = RO.BMQID
	WHERE BMQ.Brand = @Brand
		AND BMQ.ISOAlpha3 = @Market
		AND BMQ.Questionnaire = @Questionnaire


	--------------------------------------------------------------------------------
	-- GET THE RE OUTPUTTED CASES FROM SelectionOutput.ReOutputTelephone
	--------------------------------------------------------------------------------
	INSERT INTO SelectionOutput.CATI
	(
		VIN, 
		DealerCode, 
		ModelDesc, 
		CoName, 
		Add1, 
		Add2, 
		Add3, 
		Add4, 
		Add5, 
		LandPhone, 
		WorkPhone, 
		MobilePhone,
		PartyID, 
		CaseID, 
		DateOutput, 
		JLR, 
		EventTypeID, 
		RegNumber, 
		RegDate, 
		LocalName, 
		EventDate,
		SelectionOutputPassword,
		GDDDealerCode,			-- V1.3
		ReportingDealerPartyID, -- V1.3
		VariantID,				-- V1.3
		ModelVariant,			-- V1.3
		ReOutputFlag,			-- V1.7
		[Queue],				-- V1.11
		AssignedMode,			-- V1.11
		RequiresManualDial,		-- V1.11
		CallRecordingsCount,	-- V1.11
		TimeZone,				-- V1.11
		CallOutcome,			-- V1.11
		PhoneNumber,			-- V1.11
		PhoneSource,			-- V1.11
		[Language],				-- V1.11
		ExpirationTime,			-- V1.11
		HomePhoneNumber,		-- V1.11
		WorkPhoneNumber,		-- V1.11
		MobilePhoneNumber		-- V1.11
	)
	SELECT 
		RO.VIN, 
		RO.DealerCode, 
		RO.ModelDesc, 
		RO.CoName, 
		RO.Add1, 
		RO.Add2, 
		RO.Add3, 
		RO.Add4, 
		RO.Add5,
		RO.LandPhone, 
		RO.WorkPhone, 
		RO.MobilePhone,
		RO.PartyID, 
		RO.CaseID, 
		RO.DateOutput, 
		RO.JLR, 
		RO.EventTypeID, 
		RO.RegNumber, 
		RO.RegDate, 
		RO.LocalName, 
		RO.EventDate,
		RO.SelectionOutputPassword,
		RO.GDDDealerCode,			-- V1.3
		RO.ReportingDealerPartyID,	-- V1.3
		RO.VariantID,				-- V1.3
		RO.ModelVariant,			-- V1.3
		1 AS ReOutputFlag,			-- V1.7
		'FRESH' AS [Queue],
		'Phone' AS AssignedMode,
		1 AS RequiresManualDial,
		1 AS CallRecordingsCount,
		ISNULL(CT.TimeZoneID, 0) AS TimeZone,
		'Undialled' AS CallOutcome, 
		COALESCE (	NULLIF(SelectionOutput.udfFormatTelNoForDimensions(RO.MobilePhone, CD.CountryID), ''),
					NULLIF(SelectionOutput.udfFormatTelNoForDimensions(RO.LandPhone, CD.CountryID), ''),
					NULLIF(SelectionOutput.udfFormatTelNoForDimensions(RO.WorkPhone, CD.CountryID), ''),
					'') AS PhoneNumber,
		CASE	WHEN ISNULL(RO.MobilePhone, '') <> '' THEN 'MobilePhoneNumber'
				WHEN ISNULL(RO.LandPhone, '') <> '' THEN 'HomePhoneNumber'
				WHEN ISNULL(RO.WorkPhone, '') <> '' THEN 'WorkPhoneNumber'
				ELSE ''	END AS PhoneSource,
		CASE	WHEN LV.LanguageID IS NULL THEN ISNULL(DL.LanguageCode, '')
				ELSE ISNULL(DL2.LanguageCode, '') END AS [Language], 
		--EXPIRES AT MIDNIGHT																																													-- V1.22
		CONVERT (DATETIME, CONVERT(VARCHAR(10), DATEADD(dd, BMQM.NumDaysToExpireOnlineQuestionnaire, @dtCATI), 120) + '  23:59:59') AS ExpirationTime,			
		SelectionOutput.udfFormatTelNoForDimensions(RO.LandPhone, CD.CountryID) AS HomePhoneNumber,
		SelectionOutput.udfFormatTelNoForDimensions(RO.WorkPhone, CD.CountryID) AS WorkPhoneNumber,
		SelectionOutput.udfFormatTelNoForDimensions(RO.MobilePhone, CD.CountryID) AS MobilePhoneNumber
	FROM SelectionOutput.ReOutputTelephone RO
		INNER JOIN (	SELECT DISTINCT 
							BMQID,
							Brand,
							ISOAlpha3,
							Questionnaire
						FROM dbo.vwBrandMarketQuestionnaireSampleMetadata) BMQ ON BMQ.BMQID = RO.BMQID
		INNER JOIN Meta.Casedetails CD ON RO.CaseID	= CD.CaseID
		INNER JOIN dbo.BrandMarketQuestionnaireMetadata BMQM ON BMQ.BMQID = BMQM.BMQID
		LEFT JOIN Dimensions.CountryAndTimezone CT ON CD.CountryID = CT.CountryID
		LEFT JOIN Dimensions.DimensionsLanguage DL ON CD.LanguageID = DL.LanguageID
		LEFT JOIN Dimensions.LanguageVariation LV ON CD.LanguageID = LV.LanguageID 
													AND CD.CountryID = LV.CountryID
		LEFT JOIN Dimensions.DimensionsLanguage DL2 ON LV.DimensionsLanguageID = DL2.DimensionsLanguageID
	WHERE BMQ.Brand = @Brand
		AND BMQ.ISOAlpha3 = @Market
		AND BMQ.Questionnaire = @Questionnaire

	UPDATE SO
	SET SO.LocalName = ISNULL(CD.Title, '') + ' ' + ISNULL(CD.FirstName, '') + ' ' + ISNULL(CD.LastName, '')
	FROM Meta.CaseDetails CD
		INNER JOIN SelectionOutput.CATI SO ON CD.CaseID = SO.CaseID
	WHERE CD.Country = 'South Africa'	
	
	
	--------------------------------------------------------------------------------
	-- GET THE RE OUTPUTTED CASES FROM SelectionOutput.ReOutputEmail
	--------------------------------------------------------------------------------
	INSERT INTO SelectionOutput.Email
		(
			[Password],
			[ID],
			FullModel,
			Model,
			sType,
			CarReg,
			Title,
			Initial,
			Surname,
			Fullname,
			DearName,
			CoName,
			Add1,
			Add2,
			Add3,
			Add4,
			Add5,
			Add6,
			Add7,
			Add8,
			Add9,
			CTRY,
			EmailAddress,
			Dealer,
			sno,
			ccode,
			modelcode,
			lang,
			manuf,
			gender,
			qver,
			blank,
			etype,
			reminder,
			[week],
			test,
			SampleFlag,
			SalesServiceFile,
			DealerCode,
			VIN,
			EventDate,
			LandPhone,
			WorkPhone,
			MobilePhone,
			PartyID,
			GDDDealerCode, 
			ReportingDealerPartyID, 
			VariantID,  
			ModelVariant,
			ReoutputIndicator,		
			BilingualFlag,		-- V1.23	
			langBilingual,		-- V1.23
			DearNameBilingual	-- V1.23
		)
		SELECT DISTINCT
			SelectionOutputPassword,
			[ID],
			FullModel,
			Model,
			sType,
			CarReg,
			Title,
			Initial,
			Surname,
			Fullname,
			DearName,
			CoName,
			Add1,
			Add2,
			Add3,
			Add4,
			Add5,
			Add6,
			Add7,
			Add8,
			Add9,
			CTRY,
			EmailAddress,
			Dealer,
			sno,
			ccode,
			modelcode,
			lang,
			manuf,
			gender,
			qver,
			blank,
			etype,
			reminder,
			[week],
			test,
			SampleFlag,
			SalesServiceFile,
			DealerCode,
			VIN,
			EventDate,
			LandPhone,
			WorkPhone,
			MobilePhone,
			PartyID,
			GDDDealerCode, 
			ReportingDealerPartyID, 
			VariantID, 
			ModelVariant,
			1 AS ReoutputIndicator,	
			RO.BilingualFlag,		-- V1.23
			RO.langBilingual,		-- V1.23
			RO.DearNameBilingual	-- V1.23	
		FROM SelectionOutput.ReOutputEmail RO
	
	
	--------------------------------------------------------------------------------
	-- GET THE RE OUTPUTTED CASES FROM SelectionOutput.ReOutputSMS		-- V1.13
	--------------------------------------------------------------------------------
	INSERT INTO SelectionOutput.SMS
		(
			[Password],
			[ID],
			FullModel,
			Model,
			sType,
			CarReg,
			Title,
			Initial,
			Surname,
			Fullname,
			DearName,
			CoName,
			Add1,
			Add2,
			Add3,
			Add4,
			Add5,
			Add6,
			Add7,
			Add8,
			Add9,
			CTRY,
			EmailAddress,
			Dealer,
			sno,
			ccode,
			modelcode,
			lang,
			manuf,
			gender,
			qver,
			blank,
			etype,
			reminder,
			[week],
			test,
			SampleFlag,
			SalesServiceFile,
			DealerCode,
			VIN,
			EventDate,
			LandPhone,
			WorkPhone,
			MobilePhone,
			PartyID,
			GDDDealerCode, 
			ReportingDealerPartyID, 
			VariantID,  
			ModelVariant,
			ReoutputIndicator,		-- V1.14
			BilingualFlag,			-- V1.23	
			langBilingual,			-- V1.23
			DearNameBilingual,		-- V1.23
			FirstName				-- V1.24			
		)
		SELECT DISTINCT
			SelectionOutputPassword,
			[ID],
			FullModel,
			Model,
			sType,
			CarReg,
			Title,
			Initial,
			Surname,
			Fullname,
			DearName,
			CoName,
			Add1,
			Add2,
			Add3,
			Add4,
			Add5,
			Add6,
			Add7,
			Add8,
			Add9,
			CTRY,
			EmailAddress,
			Dealer,
			sno,
			ccode,
			modelcode,
			lang,
			manuf,
			gender,
			qver,
			blank,
			etype,
			reminder,
			[week],
			test,
			SampleFlag,
			SalesServiceFile,
			DealerCode,
			VIN,
			EventDate,
			LandPhone,
			WorkPhone,
			MobilePhone,
			PartyID,
			GDDDealerCode, 
			ReportingDealerPartyID, 
			VariantID, 
			ModelVariant,
			1 AS ReoutputIndicator,
			RO.BilingualFlag,		-- V1.23
			RO.langBilingual,		-- V1.23
			RO.DearNameBilingual,	-- V1.23
			RO.FirstName			-- V1.24
		FROM SelectionOutput.ReOutputSMS RO		
	
	
	--------------------------------------------------------------------------------
	-- UPDATE THE MODELS FOR POSTAL OUTPUT
	--------------------------------------------------------------------------------
	UPDATE SelectionOutput.Postal
	SET FullModel = CASE	WHEN FullModel LIKE '%S-TYPE%' THEN 'S-TYPE'
							WHEN FullModel LIKE '%XJ%' THEN 'XJ'
							WHEN FullModel LIKE '%XK%' THEN 'XK'
							WHEN FullModel LIKE '%X-TYPE%' THEN 'X-TYPE'
							WHEN FullModel LIKE '%XF Sportbrake%' THEN 'XF Sportbrake'
							WHEN FullModel LIKE '%XF%' THEN 'XF'
							WHEN FullModel LIKE '%F-TYPE%' THEN 'F-TYPE'
							WHEN FullModel LIKE '%XE%' THEN 'XE'
							WHEN FullModel LIKE '%Defender%' THEN 'Defender'
							WHEN FullModel LIKE '%Freelander%' THEN 'Freelander'
							WHEN FullModel LIKE '%Range Rover Evoque%' THEN 'Range Rover Evoque'
							WHEN FullModel LIKE '%Range Rover Sport%' THEN 'Range Rover Sport'
							WHEN FullModel LIKE '%Range Rover%' THEN 'Range Rover'
							WHEN FullModel LIKE '%Discovery Sport%' THEN 'Discovery Sport'
							WHEN FullModel LIKE '%Discovery%' THEN 'Discovery'
							WHEN FullModel LIKE '%F-PACE%' THEN 'F-PACE'
							ELSE FullModel END

	UPDATE SelectionOutput.Postal
	SET Model = FullModel 		


	--------------------------------------------------------------------------------
	-- V1.21 V1.17 UPDATE SampleFile Flag for US/Canada Sales/Service Postal Output
	--------------------------------------------------------------------------------
	--UPDATE O
	--SET O.SampleFlag = 3
	--FROM SelectionOutput.Postal O
	--	INNER JOIN [Event].EventTypeCategories ETC ON ETC.EventTypeID = O.etype 
	--	INNER JOIN [Event].EventCategories EC ON ETC.EventCategoryID = EC.EventCategoryID
	--WHERE O.ccode IN (36,221)		--	Canada/USA
	--	AND EC.EventCategory IN ('Sales','Service')


	--------------------------------------------------------------------------------
	-- V1.20 UPDATE EmployeeName FOR CATI Output
	--------------------------------------------------------------------------------
	UPDATE O
	SET O.EmployeeName = AI.Salesman
	FROM [Event].AdditionalInfoSales AI				-- V1.25
		INNER JOIN [Event].AutomotiveEventBasedInterviews AEBI ON AI.EventID = AEBI.EventID     
		INNER JOIN SelectionOutput.CATI O ON AEBI.CaseID = O.CaseID
		
	
	--------------------------------------------------------------------------------
	-- SET THE STATUS OF THE SELECTION TO "OUTPUTTED"
	--------------------------------------------------------------------------------
	UPDATE SR
	SET SR.SelectionStatusTypeID = (	SELECT SelectionStatusTypeID 
										FROM Requirement.SelectionStatusTypes 
										WHERE SelectionStatusType = 'Outputted')
	FROM #SelectionRequirementIDs S
		INNER JOIN Requirement.SelectionRequirements SR ON SR.RequirementID = S.SelectionRequirementID


	--------------------------------------------------------------------------------
	-- UPDATE THE PROCESSED FLAG IN SelectionOutput.SelectionsToOutput
	--------------------------------------------------------------------------------
	UPDATE O
	SET O.Processed = 1,
		O.DateProcessed = GETDATE()
	FROM #SelectionRequirementIDs S
		INNER JOIN SelectionOutput.SelectionsToOutput O ON O.SelectionRequirementID = S.SelectionRequirementID

	DROP TABLE #SelectionRequirementIDs


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
		
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH

