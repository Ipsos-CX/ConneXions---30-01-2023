CREATE PROCEDURE [SampleReport].[uspEventReportRequired]
	@Brand VARCHAR (100), 
	@MarketRegion VARCHAR (100), 
	@Questionnaire VARCHAR (100), 
	@ReportType VARCHAR(100), 
	@ExecStatus TINYINT OUTPUT
AS
	SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

	/* DEFAULT EXEC STATUS TO 0 */

	SET @ExecStatus = 0

	/*
		Purpose:	SHOULD WE RUN A SAMPLE EVENT REPORT
			
		Version		Date				Developer			Comment
		1.0			26/08/2015			Chris Ledger		BUG 11658 - Addition of Roadside (major change for regions)
		1.1			11/10/2016			Ben King			Regional Report Fix. Can now run any Market by itself and Regional report associated will run.
	*/
	
	BEGIN TRY
		
		SELECT TOP 1
			@ExecStatus = ISNULL(BMQ.SampleEventReportOutput, 0)
		FROM [$(SampleDB)].dbo.BrandMarketQuestionnaireMetadata BMQ
		INNER JOIN [$(SampleDB)].dbo.Brands B ON BMQ.BrandID = B.BrandID
		INNER JOIN [$(SampleDB)].dbo.Markets M ON BMQ.MarketID = M.MarketID
		INNER JOIN [$(SampleDB)].dbo.Regions R ON M.RegionID = R.RegionID
		INNER JOIN [$(SampleDB)].dbo.Questionnaires Q ON BMQ.QuestionnaireID = Q.QuestionnaireID
		WHERE B.Brand = @Brand
		AND M.Market = CASE @ReportType
			WHEN 'Market' THEN @MarketRegion ELSE M.Market END
		AND R.Region = CASE @ReportType
			WHEN 'Region' THEN @MarketRegion ELSE R.Region END
		AND Q.Questionnaire = @Questionnaire
		AND BMQ.SampleLoadActive = 1
		AND BMQ.SampleReportOutput = 1

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

		SET @ExecStatus = 0
		
	END CATCH