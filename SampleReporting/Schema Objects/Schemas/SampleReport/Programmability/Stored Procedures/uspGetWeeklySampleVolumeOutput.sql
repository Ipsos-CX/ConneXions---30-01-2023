CREATE PROCEDURE [SampleReport].[uspGetWeeklySampleVolumeOutput]
@Region NVARCHAR(255)

AS

SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

	/*
		Purpose: Outputs Weekly Sample Volume Report, Selected by Region variable
			
		Releae		Version		Date				Developer			Comment
		LIVE		1.0			26/08/2015			Ben King			TASK 931 - Sample Volume Report
	*/
	
	BEGIN TRY
	
	TRUNCATE TABLE [SampleReport].[GetWeeklySampleVolumeOutput]

	INSERT INTO [SampleReport].[GetWeeklySampleVolumeOutput] (Brand, Market, Questionnaire, Frequency, BenchMark, CurrentWeekLoaded, WeekMinus1Loaded, WeekMinus2Loaded, WeekMinus3Loaded, WeekMinus4Loaded, MonthTotal)
	SELECT DISTINCT
			SV.Brand, 
			SV.Market, 
			SV.Questionnaire, 
			SV.Frequency, 
			CASE 
				WHEN SV.BenchMark IS NULL
				THEN 'No Sample received'
				ELSE SV.BenchMark
			END AS BenchMark,  
			SV.CurrentWeekLoaded,
			SV.WeekMinus1Loaded,
			SV.WeekMinus2Loaded,
			SV.WeekMinus3Loaded,
			SV.WeekMinus4Loaded,
			SV.MonthTotal
	FROM [SampleReport].[SampleVolumeWeeklyOutput] SV
	LEFT JOIN [WeeklySampleCheck].[LiveBrandMarketQuestionnaire] LV ON SV.Market = LV.Market
																    AND SV.Brand = LV.Brand
																	AND SV.Questionnaire = LV.Questionnaire
	LEFT JOIN [$(SampleDB)].dbo.Markets M ON SV.Market = COALESCE(M.DealerTableEquivMarket, M.Market)
	LEFT JOIN [$(SampleDB)].dbo.Regions R ON M.RegionID = R.RegionID 
	WHERE (@Region = 'ALL' AND R.Region IN (SELECT Region FROM [$(SampleDB)].dbo.Regions) AND CONVERT(DATE, SV.Reportdate) = CONVERT(DATE, GETDATE()))
	OR (@Region <> 'ALL' AND R.Region = @Region AND CONVERT(DATE, SV.Reportdate) = CONVERT(DATE, GETDATE()))
	ORDER BY 2,1,3
	
		
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
