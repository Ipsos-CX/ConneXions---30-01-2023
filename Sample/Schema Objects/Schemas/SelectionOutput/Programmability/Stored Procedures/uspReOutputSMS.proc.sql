CREATE PROCEDURE [SelectionOutput].[uspReOutputSMS]
@Brand [dbo].[OrganisationName], @Market [dbo].[Country], @Questionnaire [dbo].[Requirement]
AS
SET NOCOUNT ON



/*
	Purpose:	Populates the various selection output tables for use in the Selection Output package.  
		
	Version			Date			Developer			Comment
	1.0				06/10/2016		Chris Ledger		Created for BUG 13098 - Re-output of Email to SMS
	1.1				22/10/2016		Chris Ledger		BUG 13098 - Only reoutput cases since change in ContactMethodology
	1.2				23/10/2016		Chris Ledger		BUG 13098 - Update ContactMethodologyTypeID when SelectionOutputActive = 1
	1.3				04/11/2016		Chris Ledger		BUG 13292 - VIN and sType being inserted in wrong order
	1.4				13/04/2017		Chris Ledger		BUG 13853 - Set SampleFlag to 0
	1.5				24/10/2017		Chris Ross			BUG 14245 - Update to include population of new bilingual columns.			
	1.6				09/01/2018		Eddie Thomas		BUG 14362 - Online files – Re-output records to be output once a week 
	1.7				11/08/2018		Eddie Thomas		BUG 14797 - Portugal Roadside - Contact Methodology Change request
	1.8				29/08/2019		Chris Ross			BUG 15542 - Change the DATETIME to DATETIME2 for ActionDate in temp table as comparisons not working correctly.
*/


DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN
	
		-- CREATE A TEMPORARY TABLE TO HOLD THE CASES WE NEED TO REOUTPUT
		CREATE TABLE #CasesToReOutput
		(
			CaseID BIGINT,
			OutcomeCode INT,
			ActionDate DATETIME2   -- v1.8
		)

		-- GET THE CASES WE NEED TO REOUTPUT
		INSERT INTO #CasesToReOutput
		(
			CaseID,
			OutcomeCode,
			ActionDate
		)
		
		SELECT DISTINCT
			CCMO.CaseID,
			CCMO.OutcomeCode,
			CCMO.ActionDate
		FROM Event.CaseContactMechanismOutcomes		CCMO
		INNER JOIN SelectionOutput.ReoutputCases	REOU ON CCMO.CaseID = REOU.CaseID
		--INNER JOIN ContactMechanism.OutcomeCodes OC ON OC.OutcomeCode = CCMO.OutcomeCode
		--INNER JOIN Event.CaseContactMechanisms CCM ON CCM.CaseID = CCMO.CaseID
		--LEFT JOIN Event.CaseRejections CR ON CR.CaseID = CCMO.CaseID
		--INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CCMO.CaseID
		--INNER JOIN Event.EventPartyRoles EPR ON EPR.EventID = AEBI.EventID
		--INNER JOIN dbo.DW_JLRCSPDealers D ON D.OutletPartyID = EPR.PartyID AND D.OutletFunctionID = EPR.RoleTypeID
		--inner join ContactMechanism.DealerCountries dc on dc.PartyIDFrom = epr.PartyID 
													  --and dc.RoleTypeIDFrom = epr.RoleTypeID -- Get Dealer country code for BMQ
		--inner join ContactMechanism.Countries c on c.CountryID = dc.CountryID -- Get the country ISO for filtering on
		--INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = CCMO.CaseID 
		--INNER JOIN Requirement.RequirementRollups RR ON RR.RequirementIDMadeUpOf = SC.RequirementIDPartOf 
		--INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ 
							--ON BMQ.CountryID = dc.CountryID
							--AND BMQ.QuestionnaireRequirementID = RR.RequirementIDPartOf 
							--AND BMQ.ContactMethodologyTypeID = (SELECT ContactMethodologyTypeID FROM SelectionOutput.ContactMethodologyTypes WHERE ContactMethodologyType = 'Mixed (Email & SMS)')
							--AND CCMO.ActionDate >= ISNULL(BMQ.ContactMethodologyFromDate,'2000-01-01')	-- V1.5  
						
		--WHERE OC.CausesReOutput = 1
		--AND CCMO.ReOutputProcessed = 0
		--AND CR.CaseID IS NULL
		--AND D.Manufacturer = @Brand
		--AND (   REPLACE(D.OutletFunction, 'Aftersales', 'Service') = @Questionnaire		-- v1.3
			 --OR (D.OutletFunction = 'Sales' AND @Questionnaire = 'LostLeads')			-- v1.3
			--)
		--AND CASE
			--WHEN C.ISOAlpha3 = 'LUX' THEN 'BEL'
			--ELSE C.ISOAlpha3
		--END = @Market
		
		WHERE	REOU.Brand = @Brand 
				AND REOU.Market = @Market
				AND REOU.Questionnaire = @Questionnaire
				AND REOU.ContactMethodology = 'SMS'

		-- GET THE OUTPUT INFORMATION FOR THE CASES WE NEED TO REOUTPUT
		; WITH SMS AS (
			SELECT DISTINCT
				CCM.CaseID,
				TN.ContactNumber
			FROM Event.CaseContactMechanisms CCM
			INNER JOIN ContactMechanism.vwTelephoneNumbers TN ON CCM.ContactMechanismID = TN.ContactMechanismID
			LEFT JOIN ContactMechanism.NonSolicitations CMNS ON CMNS.ContactMechanismID = CCM.ContactMechanismID
			WHERE CMNS.ContactMechanismID IS NULL
			AND TN.ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (mobile)')
		)
		
		INSERT INTO SelectionOutput.ReOutputSMS
		(
			SelectionOutputPassword, 
			ID, 
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
			week, 
			test, 
			SampleFlag, 
			SalesServiceFile, 
			EventDate, 
			DealerCode, 
			LandPhone, 
			WorkPhone, 
			MobilePhone, 
			PartyID, 
			VariantID, 
			ModelVariant,
			Firstname	--v1.7
		)
		SELECT DISTINCT
			EC.SelectionOutputPassword, 
			CD.CaseID AS [ID],
			FullModel =
				CASE
					WHEN BMQ.Brand = 'Jaguar' THEN 'Jaguar ' + CD.ModelDescription
					ELSE CD.ModelDescription
				END,
			Model =
				CASE
					WHEN BMQ.Brand = 'Jaguar' THEN 'Jaguar ' + CD.ModelDescription
					ELSE CD.ModelDescription
				END,
			CD.VIN,				-- V1.3 Swapped Round
			BMQ.Brand AS sType,	-- V1.3 Swapped Round
			CD.RegistrationNumber AS CarReg, 
			CD.Title, 
			COALESCE(NULLIF(CD.FirstName, ''), NULLIF(CD.Initials, '')) AS Initial,
			CD.LastName AS Surname, 
			Party.udfGetAddressingText(CD.PartyID, CD.QuestionnaireRequirementID, CD.CountryID, CD.LanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Addressing')) AS FullName,
			Party.udfGetAddressingText(CD.PartyID, CD.QuestionnaireRequirementID, CD.CountryID, CD.LanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Salutation')) AS DearName, 
			CD.OrganisationName AS CoName,
			ISNULL(PA.BuildingName, '') AS Add1, 
			ISNULL(PA.SubStreet, '') AS Add2, 
			ISNULL(PA.Street, '') AS Add3, 
			ISNULL(PA.SubLocality, '') AS Add4, 
			ISNULL(PA.Locality, '') AS Add5, 
			ISNULL(PA.Town, '') AS Add6, 
			ISNULL(PA.Region, '') AS Add7, 
			ISNULL(PA.PostCode, '') AS Add8,
			'' AS Add9,
			ISNULL(PA.Country, '') AS CTRY,
			'' AS EmailAddress,
			CD.DealerName AS Dealer,
			CONVERT(VARCHAR, CD.EventTypeID)
				+ SUBSTRING('000', 1, 3 - LEN(CD.CountryID))
				+ CONVERT(VARCHAR, CD.CountryID)
				+ SUBSTRING('00000', 1, 5 - LEN(CD.ManufacturerPartyID))
				+ CONVERT(VARCHAR, CD.ManufacturerPartyID)
				+ CAST(CD.SelectionTypeID AS VARCHAR)
				+ CAST(CD.QuestionnaireVersion AS VARCHAR)
			AS sno,
			CD.CountryID AS ccode,
			CD.ModelRequirementID AS ModelCode,
			CD.LanguageID AS lang,
			CD.ManufacturerPartyID AS manuf,
			CD.GenderID AS Gender,
			CD.QuestionnaireVersion AS qver,
			'' AS blank,
			CD.EventTypeID AS etype,
			1 AS reminder,
			SelectionOutput.udfGetWeekNumber(GETDATE()) AS [week],
			1 AS test,
			0 AS SampleFlag,		-- V1.4
			'' AS SalesServiceFile,
			CD.EventDate,
			CD.DealerCode,
			'' AS LandPhone,
			'' AS WorkPhone,
			ISNULL(S.ContactNumber, '') AS MobileNumber,
			CD.PartyID 
			, CD.VariantID
			, CD.ModelVariant
			, CD.FirstName --v1.7
			
		FROM #CasesToReOutput CO
		INNER JOIN Meta.CaseDetails CD ON CD.CaseID = CO.CaseID
		INNER JOIN Event.Cases EC ON EC.CaseID = CO.CaseID
		INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON BMQ.ManufacturerPartyID = CD.ManufacturerPartyID
																	AND BMQ.ISOAlpha3 = CD.CountryISOAlpha3
																	AND BMQ.QuestionnaireRequirementID = CD.QuestionnaireRequirementID
		INNER JOIN ContactMechanism.Countries C ON C.CountryID = CD.CountryID
		LEFT JOIN Event.CaseContactMechanisms CCM ON CD.CaseID = CCM.CaseID
												AND CCM.ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Postal address')  -- v1.1 switched to LEFT join 
		LEFT JOIN Requirement.SelectionCases SC ON CD.CaseID = SC.CaseID   -- v1.1 modified to use CaseDetails rather than CaseContactMechanism CaseID (which doesn't exist if no postal address) + switched to LEFT join 
		LEFT JOIN Requirement.RequirementRollups SQ ON SQ.RequirementIDMadeUpOf = SC.RequirementIDPartOf -- ROLL UP FROM SELECTION TO QUESTIONNAIRE   -- v1.1 switched to LEFT join
		LEFT JOIN ContactMechanism.vwPostalAddresses PA ON CCM.ContactMechanismID = PA.ContactMechanismID 
		LEFT JOIN SMS S ON S.CaseID = CD.CaseID


		-- Remove records with no mobile			-- Added here as slowing down previous query too much
		DELETE FROM SelectionOutput.ReOutputSMS WHERE MobilePhone = ''
	
	
		-- Add in the Telephone fields for output in the On-line file.   -- v1.2
		UPDATE SelectionOutput.ReOutputSMS
		SET LandPhone = ContactMechanism.TelephoneNumbers.ContactNumber
		FROM Event.CaseContactMechanisms CM 
		INNER JOIN ContactMechanism.TelephoneNumbers ON CM.ContactMechanismID = ContactMechanism.TelephoneNumbers.ContactMechanismID
		INNER JOIN ContactMechanism.ContactMechanismTypes CMT ON CM.ContactMechanismTypeID = CMT.ContactMechanismTypeID 
															AND CMT.ContactMechanismType = N'Phone (landline)' 
		WHERE SelectionOutput.ReOutputSMS.ID = CM.CaseID

		UPDATE SelectionOutput.ReOutputSMS
		SET WorkPhone = ContactMechanism.TelephoneNumbers.ContactNumber
		FROM Event.CaseContactMechanisms CM 
		INNER JOIN ContactMechanism.TelephoneNumbers ON CM.ContactMechanismID = ContactMechanism.TelephoneNumbers.ContactMechanismID
		INNER JOIN ContactMechanism.ContactMechanismTypes CMT ON CM.ContactMechanismTypeID = CMT.ContactMechanismTypeID 
															AND CMT.ContactMechanismType = N'Phone' 
		WHERE SelectionOutput.ReOutputSMS.ID = CM.CaseID


	
		-- write new dealer code and transferpartyid to the reoutput details table
		UPDATE ROP
			SET GDDDealerCode = D.OutletCode_GDD
			, ReportingDealerPartyID = D.TransferPartyID
		FROM SelectionOutput.ReOutputEmail rop
		INNER JOIN Meta.CaseDetails CD ON ROP.[ID] = CD.CaseID
		INNER JOIN Event.EventTypes et ON et.EventTypeID = CD.EventTypeID				--v1.2
									  AND et.RelatedOutletFunctionID IS NOT NULL
		INNER JOIN 
			(
				SELECT DISTINCT
					OutletPartyID
					, OutletFunctionID
					, ISNULL(OutletCode_GDD, '') OutletCode_GDD
					, TransferPartyID
				FROM dbo.DW_JLRCSPDealers
			) D
		ON CD.DealerPartyID = D.OutletPartyID
		AND et.RelatedOutletFunctionID = D.OutletFunctionID								--v1.2
	

		------------------------------------------------------------------------------------------------------------
		-- Calculate whether bilingual and populate columns accordingly.				-- V1.5
		------------------------------------------------------------------------------------------------------------

		DECLARE @CanadianFrenchLanguageID INT,
				@AmericanEnglishLanguageID  INT
		SELECT @CanadianFrenchLanguageID = LanguageID FROM dbo.Languages WHERE Language = 'Canadian French (Canada)' 
		SELECT @AmericanEnglishLanguageID = LanguageID FROM dbo.Languages WHERE Language = 'American English (USA & Canada)' 

		-- Update Non-CRC recs using DealerCode lookup
		UPDATE c
		SET		c.BilingualFlag = 1,
				c.lang = @AmericanEnglishLanguageID ,
				c.langBilingual = @CanadianFrenchLanguageID ,
				c.DearName = Party.udfGetAddressingText(CD.PartyID, CD.QuestionnaireRequirementID, CD.CountryID, @AmericanEnglishLanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Salutation')),
				c.Fullname = Party.udfGetAddressingText(CD.PartyID, CD.QuestionnaireRequirementID, CD.CountryID, @AmericanEnglishLanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Addressing')),
				c.DearNameBilingual = Party.udfGetAddressingText(CD.PartyID, CD.QuestionnaireRequirementID, CD.CountryID, @CanadianFrenchLanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Salutation'))
		FROM SelectionOutput.ReOutputSMS c
		INNER JOIN Meta.CaseDetails CD ON CD.CaseID = c.ID
		WHERE CD.EventTypeID NOT IN (SELECT et.EventTypeID 
									FROM Event.EventCategories ec
									INNER JOIN Event.EventTypeCategories etc ON etc.EventCategoryID = ec.EventCategoryID 
									inner join Event.EventTypes et ON et.EventTypeID = etc.EventTypeID 
									WHERE ec.EventCategory = 'CRC'
									)
		AND c.GDDDealerCode in (select OutletCode_GDD from sample.dbo.DW_JLRCSPDealers d where d.BilingualSelectionOutput = 1)

		-- Update CRC recs using PostCode lookup
		UPDATE c
		SET		c.BilingualFlag = 1,
				c.lang = @AmericanEnglishLanguageID ,
				c.langBilingual = @CanadianFrenchLanguageID ,
				c.DearName = Party.udfGetAddressingText(CD.PartyID, CD.QuestionnaireRequirementID, CD.CountryID, @AmericanEnglishLanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Salutation')),
				c.Fullname = Party.udfGetAddressingText(CD.PartyID, CD.QuestionnaireRequirementID, CD.CountryID,  @AmericanEnglishLanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Addressing')),
				c.DearNameBilingual = Party.udfGetAddressingText(CD.PartyID, CD.QuestionnaireRequirementID, CD.CountryID, @CanadianFrenchLanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Salutation'))
		FROM SelectionOutput.ReOutputSMS c
		INNER JOIN Meta.CaseDetails CD ON CD.CaseID = c.ID
		INNER JOIN ContactMechanism.PostalAddresses pa ON pa.ContactMechanismID = PostalAddressContactMechanismID
		INNER JOIN SelectionOutput.BilingualOutputPostcodes bop ON bop.CountryID = CD.CountryID 
																	  AND ISNULL(pa.PostCode,'') LIKE bop.PostCodeMatchString 
																	  AND bop.Enabled = 1
		WHERE CD.EventTypeID IN   ( SELECT et.EventTypeID 
									FROM Event.EventCategories ec
									INNER JOIN Event.EventTypeCategories etc ON etc.EventCategoryID = ec.EventCategoryID 
									inner join Event.EventTypes et ON et.EventTypeID = etc.EventTypeID 
									WHERE ec.EventCategory = 'CRC'
									)

		------------------------------------------------------------------------------------------------------------
	
		

		-- SET THE CASE RE-OUTPUT AS PROCESSED AND DETERMINE IF WE HAVE BEEN ABLE TO RE-OUTPUT, I.E. THE PARTY HAD A VALID SMS
		UPDATE Event.CaseContactMechanismOutcomes
		SET	ReOutputProcessed = 1,
			ReOutputProcessDate = GETDATE(),
			ReOutputSuccess = CASE
						WHEN ISNULL([ID], 0) <> 0 THEN 1
						ELSE 0
			END
		FROM #CasesToReOutput C
		INNER JOIN Event.CaseContactMechanismOutcomes CCMO ON CCMO.CaseID = C.CaseID
							AND C.OutcomeCode = CCMO.OutcomeCode
							AND C.ActionDate = CCMO.ActionDate
		LEFT JOIN SelectionOutput.ReOutputSMS O ON O.[ID] = C.CaseID

		SELECT * 
		FROM #CasesToReOutput C
		INNER JOIN Event.CaseContactMechanismOutcomes CCMO ON CCMO.CaseID = C.CaseID
							AND C.OutcomeCode = CCMO.OutcomeCode
							AND C.ActionDate = CCMO.ActionDate
		LEFT JOIN SelectionOutput.ReOutputSMS O ON O.[ID] = C.CaseID

		DROP TABLE #CasesToReOutput


		-- GET THE ContactMethodologyTypeID FOR THE MARKET
		DECLARE @ContactMethodologyTypeID INT

		SELECT @ContactMethodologyTypeID = ContactMethodologyTypeID
		FROM dbo.vwBrandMarketQuestionnaireSampleMetadata
		WHERE Brand = @Brand
		AND ISOAlpha3 = @Market
		AND Questionnaire = @Questionnaire
		AND SelectionOutputActive = 1	-- V1.2
			
		-- SET THE ContactMethodologyTypeID VALUE IN SelectionOutput.Output SO WE CAN USE IT WHEN GENERATING THE OUTPUT FILES
		UPDATE SelectionOutput.SelectionsToOutput
		SET ContactMethodologyTypeID = @ContactMethodologyTypeID
		WHERE Brand = @Brand
		AND Market = @Market
		AND Questionnaire = @Questionnaire


	COMMIT TRAN

END TRY
BEGIN CATCH

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [Sample_Errors].dbo.uspLogDatabaseError
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
