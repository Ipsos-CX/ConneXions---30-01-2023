
CREATE PROCEDURE [SampleReport].[uspGetDailySampleVolumeOutput]
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
		Purpose: Outputs Sample Volume Report, Selected by Region variable
			
		Releae		Version		Date				Developer			Comment
		LIVE		1.0			26/08/2015			Ben King			TASK 931 - Sample Volume Report
	*/
	
	BEGIN TRY
	
	SET DATEFIRST 1

	TRUNCATE TABLE [SampleReport].[GetDailySampleVolumeOutput]

	INSERT INTO [SampleReport].[GetDailySampleVolumeOutput] (Brand, Market, Questionnaire, Frequency, ExpectedDays, Daily_Benchmark, FileRow_LoadedCount_Monday, FileRow_LoadedCount_Tuesday, FileRow_LoadedCount_Wednesday, FileRow_LoadedCount_Thursday, FileRow_LoadedCount_Friday, FileRow_LoadedCount_Saturday, FileRow_LoadedCount_Sunday, PreviousWeekDayCount, CurrentWkTotal, PreviousWkTotal, ReportDate, Region)
	SELECT DISTINCT
			SV.Brand, 
			SV.Market, 
			SV.Questionnaire, 
			SV.Frequency, 
			ISNULL(LV.ExpectedDays,'') AS ExpectedDays,
			CASE 
				WHEN SV.BenchMark IS NULL
				THEN 'No Sample received'
				ELSE SV.BenchMark
			END AS BenchMark, 
			CASE 
				WHEN (SELECT DATEPART(WEEKDAY,GETDATE())) >= 1
				THEN SV.FileRow_LoadedCount_Monday
				ELSE ''
			END AS FileRow_LoadedCount_Monday,
			CASE 
				WHEN (SELECT DATEPART(WEEKDAY,GETDATE())) >= 2
				THEN SV.FileRow_LoadedCount_Tuesday
				ELSE ''
			END AS FileRow_LoadedCount_Tuesday,
			CASE 
				WHEN (SELECT DATEPART(WEEKDAY,GETDATE())) >= 3
				THEN SV.FileRow_LoadedCount_Wednesday
				ELSE ''
			END AS FileRow_LoadedCount_Wednesday,
			CASE 
				WHEN (SELECT DATEPART(WEEKDAY,GETDATE())) >= 4
				THEN SV.FileRow_LoadedCount_Thursday
				ELSE ''
			END AS FileRow_LoadedCount_Thursday,
			CASE 
				WHEN (SELECT DATEPART(WEEKDAY,GETDATE())) >= 5
				THEN SV.FileRow_LoadedCount_Friday
				ELSE ''
			END AS FileRow_LoadedCount_Friday,
			CASE 
				WHEN (SELECT DATEPART(WEEKDAY,GETDATE())) >= 6
				THEN SV.FileRow_LoadedCount_Saturday
				ELSE ''
			END AS FileRow_LoadedCount_Saturday,
			CASE 
				WHEN (SELECT DATEPART(WEEKDAY,GETDATE())) >= 7
				THEN SV.FileRow_LoadedCount_Sunday
				ELSE ''
			END AS FileRow_LoadedCount_Sunday,

			SV.PreviousWeekDayCount, 
			SV.CurrentWkTotal, 
			SV.PreviousWkTotal, 
			SV.ReportDate,
			R.Region
	FROM [SampleReport].[SampleVolumeDailyOutput] SV
	LEFT JOIN [WeeklySampleCheck].[LiveBrandMarketQuestionnaire] LV ON SV.Market = LV.Market
																    AND SV.Brand = LV.Brand
																	AND SV.Questionnaire = LV.Questionnaire
	LEFT JOIN [$(SampleDB)].dbo.Markets M ON SV.Market = COALESCE(M.DealerTableEquivMarket, M.Market)
	LEFT JOIN [$(SampleDB)].dbo.Regions R ON M.RegionID = R.RegionID 
	WHERE (@Region = 'ALL' AND R.Region IN (SELECT Region FROM [$(SampleDB)].dbo.Regions) AND CONVERT(DATE, SV.Reportdate) = CONVERT(DATE, GETDATE()))
	OR (@Region <> 'ALL' AND R.Region = @Region AND CONVERT(DATE, SV.Reportdate) = CONVERT(DATE, GETDATE()))
	ORDER BY 2,1,3

	--THIS CODE EXPORTS DYNAMIC HEADER TEXT AS WELL. BEEN REMOVED AS HEADER IS CALCULATED IN TEMPLATE
	--TO ALLOW EXCEL FILTERS TO WORK
	--INSERT INTO [SampleReport].[GetDailySampleVolumeOutput] (Brand, Market, Questionnaire, Frequency, Daily_Benchmark, FileRow_LoadedCount_Monday, FileRow_LoadedCount_Tuesday, FileRow_LoadedCount_Wednesday, FileRow_LoadedCount_Thursday, FileRow_LoadedCount_Friday, FileRow_LoadedCount_Saturday, FileRow_LoadedCount_Sunday, PreviousWeekDayCount, CurrentWkTotal, PreviousWkTotal, ReportDate, Region)
	--SELECT 
	--		SV.Brand, 
	--		SV.Market, 
	--		SV.Questionnaire, 
	--		SV.Frequency, 
	--		SV.BenchMark, 
	--		SV.FileRow_LoadedCount_Monday, 
	--		SV.FileRow_LoadedCount_Tuesday, 
	--		SV.FileRow_LoadedCount_Wednesday, 
	--		SV.FileRow_LoadedCount_Thursday, 
	--		SV.FileRow_LoadedCount_Friday, 
	--		SV.FileRow_LoadedCount_Saturday, 
	--		SV.FileRow_LoadedCount_Sunday, 
	--		SV.PreviousWeekDayCount, 
	--		SV.CurrentWkTotal, 
	--		SV.PreviousWkTotal, 
	--		SV.ReportDate,
	--		R.Region
	--FROM [SampleReport].[SampleVolumeDailyOutput] SV
	--LEFT JOIN [WeeklySampleCheck].[LiveBrandMarketQuestionnaire] LV ON SV.Market = LV.Market
	--															    AND SV.Brand = LV.Brand
	--																AND SV.Questionnaire = LV.Questionnaire
	--LEFT JOIN [$(SampleDB)].dbo.Markets M ON SV.Market = COALESCE(M.DealerTableEquivMarket, M.Market)
	--LEFT JOIN [$(SampleDB)].dbo.Regions R ON M.RegionID = R.RegionID 
	--WHERE (@Region = 'ALL' AND R.Region IN (SELECT Region FROM [$(SampleDB)].dbo.Regions) AND CONVERT(DATE, SV.Reportdate) = CONVERT(DATE, GETDATE()))
	--OR (@Region <> 'ALL' AND R.Region = @Region AND CONVERT(DATE, SV.Reportdate) = CONVERT(DATE, GETDATE()))
	--OR (SV.HeaderID = 1 AND CONVERT(DATE, SV.Reportdate) = CONVERT(DATE, GETDATE()))
	--ORDER BY SV.HeaderID DESC
	
		
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

