CREATE PROCEDURE [SampleReport].[uspGetSampleReportsToRun]
@EchoFeed BIT=0, @DailyEcho BIT=0

AS

SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

	/*
		Purpose: WHAT BRANDS, MARKETS/REGIONS AND QUESTIONNAIRES WE WANT TO RUN SAMPLE REPORTS FOR 
			
		Version		Date				Developer			Comment
		1.0			26/08/2015			Chris Ledger		BUG 11658 - Addition of Roadside (major change for regions)
		1.1			08/06/2016			Chris Ledger		Add Region Reports for Sales/Service
		1.2			01/09/2016			Chris Ross			BUG 12859 - Add in Lost Leads questionnaire
		1.3			17/10/2016			Ben King			Run Roadside for all Questionnaires
		1.4			24/10/2016			Ben King			BUG 13257 Enable all Regional reports for Echo upload (only uploading regional files)
		1.5			25/10/2016			Ben King			BUG 13257 Only run Regional echo report for weekly upload.
		1.6			30/05/2017			Ben King			BUG 13942 - Echo Sample Reporting on a Daily Basis
		1.7			08/09/2017			Eddie Thomas		BUG 14141 - New Bodyshop questionnaire
		1.8			29/10/2019			Chris Ledger		BUG 15490 - Add PreOwned LostLeads
		1.9			17/06/2021			Ben King			TASK 495 - Sample reporting for General Enquiries
		1.10        14/10/2021          Ben King            TASK 647 - 18361 - New Supernational and Business region for Japan - added Region Japan BR
		
	*/
	
	BEGIN TRY
	
	IF @EchoFeed = 0 AND @DailyEcho = 0 -- V1.5, V1.6

		SELECT DISTINCT 
			B.Brand
			, M.Market AS MarketRegion
			, Q.Questionnaire
			, 'Market' AS ReportType
		FROM [$(SampleDB)].dbo.BrandMarketQuestionnaireMetadata BMQ
		INNER JOIN [$(SampleDB)].dbo.Brands B ON BMQ.BrandID = B.BrandID
		INNER JOIN [$(SampleDB)].dbo.Markets M ON BMQ.MarketID = M.MarketID
		INNER JOIN [$(SampleDB)].dbo.Questionnaires Q ON BMQ.QuestionnaireID = Q.QuestionnaireID
		INNER JOIN [$(SampleDB)].dbo.Regions R ON M.RegionID = R.RegionID
		WHERE	
			ISNULL(BMQ.SampleReportOutput, 0) = 1 
			AND BMQ.SampleLoadActive = 1
			AND (Q.Questionnaire IN ('Sales','Service','PreOwned','CRC', 'LostLeads','Roadside','Bodyshop','PreOwned LostLeads', 'CRC General Enquiry'))	-- V1.1, V1.3 & V1.7, V1.8, V1.9
		UNION
		SELECT DISTINCT 
			B.Brand
			, R.Region AS MarketRegion
			, Q.Questionnaire
			, 'Region' AS ReportType
		FROM [$(SampleDB)].dbo.BrandMarketQuestionnaireMetadata BMQ
		INNER JOIN [$(SampleDB)].dbo.Brands B ON BMQ.BrandID = B.BrandID
		INNER JOIN [$(SampleDB)].dbo.Markets M ON BMQ.MarketID = M.MarketID
		INNER JOIN [$(SampleDB)].dbo.Questionnaires Q ON BMQ.QuestionnaireID = Q.QuestionnaireID
		INNER JOIN [$(SampleDB)].dbo.Regions R ON M.RegionID = R.RegionID
		WHERE	
			ISNULL(BMQ.SampleReportOutput, 0) = 1 
			AND BMQ.SampleLoadActive = 1
			AND (R.Region IN ('Asia Pacific Importers','Latin America & Caribbean','MENA','Sub Saharan Africa','European Importers','European NSC','North America NSC','Overseas NSC','UK BR','Japan BR')) -- V1.1, V1.3, V1.4
		GROUP BY 	B.Brand
			, R.Region
			, Q.Questionnaire
		ORDER BY Brand, Questionnaire
		
	ELSE IF @EchoFeed = 1 OR @DailyEcho = 1
	
	SELECT DISTINCT 
			B.Brand
			, R.Region AS MarketRegion
			, Q.Questionnaire
			, 'Region' AS ReportType
		FROM [$(SampleDB)].dbo.BrandMarketQuestionnaireMetadata BMQ
		INNER JOIN [$(SampleDB)].dbo.Brands B ON BMQ.BrandID = B.BrandID
		INNER JOIN [$(SampleDB)].dbo.Markets M ON BMQ.MarketID = M.MarketID
		INNER JOIN [$(SampleDB)].dbo.Questionnaires Q ON BMQ.QuestionnaireID = Q.QuestionnaireID
		INNER JOIN [$(SampleDB)].dbo.Regions R ON M.RegionID = R.RegionID
		WHERE	
			ISNULL(BMQ.SampleReportOutput, 0) = 1 
			AND BMQ.SampleLoadActive = 1
			AND (R.Region IN ('Asia Pacific Importers','Latin America & Caribbean','MENA','Sub Saharan Africa','European Importers','European NSC','North America NSC','Overseas NSC','UK BR','Japan BR')) -- V1.1, V1.3, V1.4
		GROUP BY 	B.Brand
			, R.Region
			, Q.Questionnaire
		ORDER BY Brand, Questionnaire
		
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

