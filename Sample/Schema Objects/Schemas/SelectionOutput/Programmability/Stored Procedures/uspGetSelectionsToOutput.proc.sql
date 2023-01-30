CREATE PROCEDURE [SelectionOutput].[uspGetSelectionsToOutput]

	@ReoutputRequested  BIT = 'false'
	
AS

/*
	Purpose:	Get the list of Brand, Market and Questionnaire values for all of the authorised selections
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created from [Prophet-ODS].dbo.uspSELECTIONOUTPUT_JLR_GetOutputs
	1.1				09/01/2018		Eddie Thomas		BUG 14362 - Online files – Re-output records to be output once a week 
	1.2				26/03/2018		Eddie Thomas		Exclude postal from new re-output process
	1.3				20/11/2018		Chris Ledger		Changes to speed up running

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	--PRE-DEFINED DAY FOR  RE-OUTPUTS
	DECLARE @ReoutputDay VARCHAR(10)

	SELECT		@ReoutputDay = [ReoutputDay_SelectionOutput]
	FROM		[Meta].[System]

	TRUNCATE TABLE SelectionOutput.SelectionsToOutput

	INSERT INTO SelectionOutput.SelectionsToOutput
	(
		Brand,
		Market,
		Questionnaire,
		SelectionRequirementID,
		IncludeEmailOutputInAllFile,
		IncludePostalOutputInAllFile,
		IncludeCATIOutputInAllFile,
		IncludeSMSOutputInAllFile,
		ReOutput
	)
	SELECT DISTINCT
		BMQ.Brand,
		BMQ.ISOAlpha3,
		BMQ.Questionnaire,
		SR.RequirementID,
		BMQ.IncludeEmailOutputInAllFile,
		BMQ.IncludePostalOutputInAllFile,
		BMQ.IncludeCATIOutputInAllFile,
		BMQ.IncludeSMSOutputInAllFile,
		0 AS ReOutput
	FROM Requirement.SelectionRequirements SR
	INNER JOIN Requirement.RequirementRollups SQ ON SQ.RequirementIDMadeUpOf = SR.RequirementID
	INNER JOIN Requirement.QuestionnaireRequirements QR ON QR.RequirementID = SQ.RequirementIDPartOf
	INNER JOIN Event.EventCategories EC ON EC.EventCategoryID = QR.EventCategoryID
	INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON BMQ.CountryID = QR.CountryID
												AND BMQ.ManufacturerPartyID = QR.ManufacturerPartyID
												AND BMQ.Questionnaire = EC.EventCategory
	WHERE BMQ.SelectionOutputActive = 1
	AND SR.SelectionStatusTypeID = 4
	AND QR.ManufacturerPartyID IN (SELECT ManufacturerPartyID FROM dbo.Brands)
	AND SR.DateOutputAuthorised > '22 Sep 2009' -- GO LIVE DATE
	AND (@ReoutputRequested)='False'		--<--PREVENT THE MIXING OF NORMAL SELECTION OUTPUT AND RE-OUTPUTS V1.1

	UNION

	---- Look for any on-line expired records that need to be re-output
	--SELECT DISTINCT
		--BMQ.Brand,
		--BMQ.ISOAlpha3,
		--BMQ.Questionnaire,
		--0 AS RequirementID,
		--0 AS IncludeEmailOutputInAllFile,
		--BMQ.IncludePostalOutputInAllFile,
		--BMQ.IncludeCATIOutputInAllFile,
		--BMQ.IncludeSMSOutputInAllFile,
		--1 AS ReOutput
	--FROM [Event].[CaseContactMechanismOutcomes] OC
	--INNER JOIN Requirement.SelectionCases sc on sc.CaseID = OC.CaseID 
  	--INNER JOIN Requirement.RequirementRollups SQ ON SQ.RequirementIDMadeUpOf = sc.RequirementIDPartOf 
	--INNER JOIN Requirement.QuestionnaireRequirements QR ON QR.RequirementID = SQ.RequirementIDPartOf
	--INNER JOIN Event.EventCategories EC ON EC.EventCategoryID = QR.EventCategoryID
	--INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON BMQ.CountryID = QR.CountryID
												--AND BMQ.ManufacturerPartyID = QR.ManufacturerPartyID
												--AND BMQ.Questionnaire = EC.EventCategory
	--WHERE OC.OutcomeCode = (select OutcomeCode	from ContactMechanism.OutcomeCodes 
									--where Outcome = 'Online Expiry Date Reached' ) 
	--AND OC.ReOutputProcessed = 0
	--AND BMQ.SelectionOutputActive = 1
	--AND QR.ManufacturerPartyID IN (SELECT ManufacturerPartyID FROM dbo.Brands)
	
	--1.1 CREATE SELECTIONS TO RE-OUTPUT EVERYTHING I.E. NOT JUST EXPIRED ON-LINE RECORDS
	SELECT DISTINCT
		BMQ.Brand,
		BMQ.ISOAlpha3,
		BMQ.Questionnaire,
		0 AS RequirementID,
		0 AS IncludeEmailOutputInAllFile,
		BMQ.IncludePostalOutputInAllFile,
		BMQ.IncludeCATIOutputInAllFile,
		BMQ.IncludeSMSOutputInAllFile,
		1 AS ReOutput
	FROM		SelectionOutput.ReoutputCases RO
	INNER JOIN	Requirement.SelectionCases sc on sc.CaseID = RO.CaseID 
  	INNER JOIN	Requirement.RequirementRollups SQ ON SQ.RequirementIDMadeUpOf = sc.RequirementIDPartOf 
	INNER JOIN	Requirement.QuestionnaireRequirements QR ON QR.RequirementID = SQ.RequirementIDPartOf
	INNER JOIN	Event.EventCategories EC ON EC.EventCategoryID = QR.EventCategoryID
	INNER JOIN	dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON BMQ.CountryID = QR.CountryID
												AND BMQ.ManufacturerPartyID = QR.ManufacturerPartyID
												AND BMQ.Questionnaire = EC.EventCategory

	WHERE	(BMQ.SelectionOutputActive = 1)
			AND (QR.ManufacturerPartyID IN (SELECT ManufacturerPartyID FROM dbo.Brands))
			AND (@ReoutputRequested='true' AND DATENAME(weekday, GETDATE()) = @ReoutputDay)  

	-- RETURN THE DISTINCT BRAND, MARKET AND QUESTIONNAIRES
	SELECT DISTINCT
		Brand,
		Market,
		Questionnaire
	FROM SelectionOutput.SelectionsToOutput
	ORDER BY Brand,
		Market,
		Questionnaire

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