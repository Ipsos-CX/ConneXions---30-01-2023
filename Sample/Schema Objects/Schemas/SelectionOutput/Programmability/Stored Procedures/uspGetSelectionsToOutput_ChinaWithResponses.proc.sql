CREATE PROCEDURE [SelectionOutput].[uspGetSelectionsToOutput_ChinaWithResponses]
AS
/*
	Purpose:	Get the list of Brand, Market and Questionnaire values for China With Responses authorised selections
	
	Version			Date			Developer			Comment
	1.0				21/06/2018		Eddie Thomas		Created from SelectionOutput.uspGetSelectionsToOutput
	1.1				21/01/2020		Chris Ledger		BUG 15372: Fix Hard coded references to databases.
*/
SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	--CLEAR RE-OUTPUT TABLE
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
	AND BMQ.SelectionName Like '%CHN%Responses%'

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