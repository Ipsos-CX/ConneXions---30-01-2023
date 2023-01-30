CREATE PROCEDURE [SelectionOutput].[uspOnlineEmailContactDetails]

AS

/*
	Purpose:	Add in on-line output email contact information and remove any On-line records which don't have Email contact/signatory details
	
	Version			Date			Developer			Comment
	1.0				31/03/2015		Chris Ross			Original version. Created as part of BUG 11329.
	1.1				11/06/2015		Chris Ross			BUG 6061 - Allow CRC through with empty values as not using Email Contact Details yet.
	1.2				24/07/2015		Chris Ross			BUG 11675 - Do not delete Cases for China as they can have blank email contact details
	1.3				13/10/2016		Eddie Thomas		BUG 13226 - CRC Case should of been removed from output because the Case language isn't supported in the Invite matrix
	1.5				26/01/2017		Eddie Thomas		New JLR JLRCompanyname
	1.6				27/01/2017		Chris Ledger		BUG 13160 - Update CQI based on Questionnaire Requirement
	1.7				16/05/2017		Eddie Thomas		BUG 13682 - China Roadside With responses	
	1.8				24/10/2017		Chris Ross			BUG 14245 - Add in population of bilingual columns where appropriate.
	1.9				28/11/2017		Chris Ledger		BUG 14347 - Add MCQI
	1.10			16/03/2018		Eddie Thomas		Bug 14557 - Adding CRC with responses support
	1.11			01/06/2018		Eddie Thomas		BUG 14763 - Adding JLR PP fields
	1.12			01/11/2019		Chris Ledger		BUG 16729 - Update JLRPrivacyPolicy field for ITYPE S & T
	1.13			14/02/2021		Eddie Thomas		Mapping market name Korea to Republic of Korea
	1.14			29/04/2021		Chris Ledger		TASK 414 - Undo mapping of market name Korea to Republic of Korea
	1.15			09/09/2022		Eddie Thomas		TASK 1017 - Introduction of SubBrand
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	------------------------------------------------------------------
	-- Update Email Contact Details 
	------------------------------------------------------------------
	
	------------------------------------------------------------------
	-- Email Contact Details based on Language
	UPDATE O
	SET EmailSignator = ECD.EmailSignator,
		EmailSignatorTitle = ECD.EmailSignatorTitle,
		EmailContactText = ECD.EmailContactText,
		EmailCompanyDetails = ECD.EmailCompanyDetails,
		JLRPrivacyPolicy = ECD.JLRPrivacyPolicy,		-- V1.11
		JLRCompanyname = ECD.JLRCompanyname				-- V1.5	
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN ContactMechanism.Countries C ON C.ISOAlpha3 = O.Market
		INNER JOIN dbo.Markets M ON M.CountryID = C.CountryID
		INNER JOIN dbo.Languages L ON L.LanguageID = O.Lang
		INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = O.etype
		LEFT JOIN SelectionOutput.OnlineEmailContactDetails ECD ON ECD.Brand = stype
																AND ECD.Market = M.Market -- V1.13	-- V1.14
																AND ECD.Questionnaire = ET.EventCategory
																AND ECD.EmailLanguage = L.[Language]
																AND ECD.SubBrand      = O.SubBrand	--V1.15
		INNER JOIN Meta.CaseDetails CD ON O.ID = CD.CaseID
		INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata VW ON CD.QuestionnaireRequirementID = VW.QuestionnaireRequirementID
		INNER JOIN dbo.BrandMarketQuestionnaireMetadata MD ON VW.BMQID = MD.BMQID	
	WHERE O.ITYPE = 'H'
	------------------------------------------------------------------
	

	-----------------------------------------------------------------
	UPDATE O
	SET EmailSignator = ECD.EmailSignator,	
		EmailSignatorTitle = ECD.EmailSignatorTitle,
		EmailContactText = ECD.EmailContactText,
		EmailCompanyDetails = ECD.EmailCompanyDetails,
		JLRPrivacyPolicy = ECD.JLRPrivacyPolicy,											-- V1.11
		JLRCompanyname = CASE	WHEN MD.UseJLRCompanyname = 1 THEN ECD.JLRCompanyname		-- V1.5
								ELSE ''	END 		
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN ContactMechanism.Countries C ON C.ISOAlpha3 = O.Market
		INNER JOIN dbo.Markets M ON M.CountryID = C.CountryID
		INNER JOIN dbo.Languages L ON L.LanguageID = O.Lang
		INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = O.etype
		LEFT JOIN SelectionOutput.OnlineEmailContactDetails ECD ON ECD.Brand = O.sType
																AND ECD.Market = M.Market					-- V1.13	-- V1.14
																AND ECD.Questionnaire = ET.EventCategory
																AND ECD.EmailLanguage = L.[Language]
																AND ECD.SubBrand      = O.SubBrand			--V1.15
		INNER JOIN Meta.CaseDetails CD ON O.ID = CD.CaseID
		INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata VW ON CD.QuestionnaireRequirementID = VW.QuestionnaireRequirementID
		INNER JOIN dbo.BrandMarketQuestionnaireMetadata MD ON VW.BMQID = MD.BMQID	
	WHERE O.ITYPE = 'H' 
		AND NULLIF(O.EmailSignator,'') IS NULL
	------------------------------------------------------------------


	-------------------------------------------------------------------
	-- UPDATE CQI BASED ON QUESTIONNARE REQUIREMENT V1.6
	-------------------------------------------------------------------
	UPDATE O
	SET EmailSignator = ECD.EmailSignator,	
		EmailSignatorTitle = ECD.EmailSignatorTitle,
		EmailContactText = ECD.EmailContactText,
		EmailCompanyDetails = ECD.EmailCompanyDetails,
		JLRPrivacyPolicy = ECD.JLRPrivacyPolicy,		-- V1.11
		JLRCompanyname = CASE	WHEN MD.UseJLRCompanyname = 1 THEN ECD.JLRCompanyname	-- V1.5
								ELSE ''	END 		
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = O.ID
		INNER JOIN Requirement.Requirements R3 ON SC.RequirementIDPartOf = R3.RequirementID
		INNER JOIN ContactMechanism.Countries C ON C.ISOAlpha3 = O.Market
		INNER JOIN dbo.Markets M ON M.CountryID = C.CountryID
		INNER JOIN dbo.Languages L ON L.LanguageID = O.Lang
		INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = O.etype
		LEFT JOIN SelectionOutput.OnlineEmailContactDetails ECD ON ECD.Brand = O.sType
																AND ECD.Market = M.Market									-- V1.13	-- V1.14
																AND ECD.Questionnaire = SUBSTRING(R3.Requirement,1,3)		-- V1.10
																AND ECD.EmailLanguage = L.[Language]
																AND ECD.SubBrand      = O.SubBrand							--V1.15
		INNER JOIN Meta.CaseDetails CD ON O.ID = CD.CaseID
		INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata VW ON CD.QuestionnaireRequirementID = VW.QuestionnaireRequirementID
		INNER JOIN dbo.BrandMarketQuestionnaireMetadata MD ON VW.BMQID = MD.BMQID	
	WHERE O.ITYPE = 'H' 
		AND SUBSTRING(R3.Requirement,1,3) = 'CQI'		-- V1.10
	-------------------------------------------------------------------


	-------------------------------------------------------------------
	-- UPDATE MCQI BASED ON QUESTIONNARE REQUIREMENT V1.10
	-------------------------------------------------------------------
	UPDATE O
	SET EmailSignator = ECD.EmailSignator,	
		EmailSignatorTitle = ECD.EmailSignatorTitle,
		EmailContactText = ECD.EmailContactText,
		EmailCompanyDetails = ECD.EmailCompanyDetails,
		JLRPrivacyPolicy = ECD.JLRPrivacyPolicy,		-- V1.11
		JLRCompanyname = CASE	WHEN MD.UseJLRCompanyname = 1 THEN ECD.JLRCompanyname	-- V1.5
								ELSE ''	END 	
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = O.ID
		INNER JOIN Requirement.Requirements R3 ON SC.RequirementIDPartOf = R3.RequirementID
		INNER JOIN ContactMechanism.Countries C ON C.ISOAlpha3 = O.Market
		INNER JOIN dbo.Markets M ON M.CountryID = C.CountryID
		INNER JOIN dbo.Languages L ON L.LanguageID = O.Lang
		INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = O.etype
		LEFT JOIN SelectionOutput.OnlineEmailContactDetails ECD ON ECD.Brand = O.sType
																AND ECD.Market = M.Market									-- V1.13	-- V1.14
																AND ECD.Questionnaire = SUBSTRING(R3.Requirement,1,4)
																AND ECD.EmailLanguage = L.[Language]
																AND ECD.SubBrand      = O.SubBrand							--V1.15
		INNER JOIN Meta.CaseDetails CD ON O.ID = CD.CaseID
		INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata VW ON CD.QuestionnaireRequirementID = VW.QuestionnaireRequirementID
		INNER JOIN dbo.BrandMarketQuestionnaireMetadata MD ON VW.BMQID = MD.BMQID
	WHERE O.ITYPE = 'H' 
		AND SUBSTRING(R3.Requirement,1,4) = 'MCQI'
	-------------------------------------------------------------------
		

	------------------------------------------------------------------
	-- EXCLUDE ONLINE RECORDS WHERE NO EMAIL SIGNATORY/CONTACT DETAILS
	------------------------------------------------------------------ 
	DELETE FROM SelectionOutput.OnlineOutput
	WHERE ITYPE = 'H'
		AND COALESCE( NULLIF(EmailSignator, ''),
					  NULLIF(EmailSignatorTitle, ''),
					  NULLIF(EmailContactText, ''),
					  NULLIF(EmailCompanyDetails, '')) IS NULL
		--AND etype <> (SELECT EventTypeID FROM Event.vwEventTypes WHERE EventCategory = 'CRC')								-- V1.1		-- V1.3 
		AND NOT EXISTS (SELECT CaseID FROM Sample_ETL.China.Sales_WithResponses WHERE CaseID = OnlineOutput.ID)
		AND NOT EXISTS (SELECT CaseID FROM Sample_ETL.China.Service_WithResponses WHERE CaseID = OnlineOutput.ID)
		AND NOT EXISTS (SELECT CaseID FROM Sample_ETL.China.Roadside_WithResponses WHERE CaseID = OnlineOutput.ID)			-- V1.7
		AND NOT EXISTS (SELECT CaseID FROM Sample_ETL.China.CRC_WithResponses WHERE CaseID = OnlineOutput.ID)				-- V1.10
	------------------------------------------------------------------ 


	------------------------------------------------------------------
	-- POPULATE BILINGUAL COLUMNS, IF REQUIRED		-- V1.8
	------------------------------------------------------------------ 
	UPDATE O
	SET EmailSignatorTitleBilingual	= ECD.EmailSignatorTitle,
		EmailContactTextBilingual = ECD.EmailContactText,
		EmailCompanyDetailsBilingual = ECD.EmailCompanyDetails,
		JLRPrivacyPolicyBilingual = ECD.JLRPrivacyPolicy		-- V1.11
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN ContactMechanism.Countries C ON C.ISOAlpha3 = O.Market
		INNER JOIN dbo.Markets M ON M.CountryID = C.CountryID
		INNER JOIN dbo.Languages L ON L.LanguageID = O.LangBilingual
		INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = O.etype
		LEFT JOIN SelectionOutput.OnlineEmailContactDetails ECD ON ECD.Brand = O.sType
																AND ECD.Market = M.Market									-- V1.13	-- V1.14
																AND ECD.Questionnaire = ET.EventCategory
																AND ECD.EmailLanguage = L.[Language]
																AND ECD.SubBrand      = O.SubBrand	--V1.15
		INNER JOIN Meta.CaseDetails CD ON O.ID = CD.CaseID
		INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata VW ON CD.QuestionnaireRequirementID = VW.QuestionnaireRequirementID
		INNER JOIN dbo.BrandMarketQuestionnaireMetadata MD ON VW.BMQID = MD.BMQID	
	WHERE O.ITYPE = 'H'
		AND O.BilingualFlag = 1
	------------------------------------------------------------------ 


	-------------------------------------------------------------------
	-- UPDATE SMS & TELEPHONE RECORDS BASED ON QUESTIONNARE REQUIREMENT V1.12
	-------------------------------------------------------------------
	UPDATE O
	SET JLRPrivacyPolicy = ECD.JLRPrivacyPolicy
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN ContactMechanism.Countries C ON C.ISOAlpha3 = O.Market
		INNER JOIN dbo.Markets M ON M.CountryID = C.CountryID
		INNER JOIN dbo.Languages L ON L.LanguageID = O.Lang
		INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = O.etype
		LEFT JOIN SelectionOutput.OnlineEmailContactDetails ECD ON ECD.Brand = O.sType
																AND ECD.Market = M.Market									-- V1.13	-- V1.14
																AND ECD.Questionnaire = ET.EventCategory
																AND ECD.EmailLanguage = L.[Language]
																AND ECD.SubBrand      = O.SubBrand	--V1.15
		INNER JOIN Meta.CaseDetails CD ON O.ID = CD.CaseID
		INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata  VW ON CD.QuestionnaireRequirementID = VW.QuestionnaireRequirementID
		INNER JOIN dbo.BrandMarketQuestionnaireMetadata MD ON VW.BMQID = MD.BMQID	
	WHERE O.ITYPE IN ('S','T')
	-------------------------------------------------------------------


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