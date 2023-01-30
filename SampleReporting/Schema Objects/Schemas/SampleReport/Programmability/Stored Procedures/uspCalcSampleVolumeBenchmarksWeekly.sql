
CREATE PROCEDURE [SampleReport].[uspCalcSampleVolumeBenchmarksWeekly]
@ThreeMonth BIT = 0,
@SixMonth BIT = 0,
@Year BIT = 0
AS
SET NOCOUNT ON

/*
	Purpose:	Calculates Weekly Benchmark figures by variable time period
			
	Release			Version			Date			Developer			Comment
	LIVE			1.0				28/07/2022		Ben King			TASK 931 - Sample Volume Report
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY

	------------------------------------------------------------------------
	-- New BuildTypes & Date variables
	------------------------------------------------------------------------
	DECLARE @Build VARCHAR (20) =	CASE
										WHEN @ThreeMonth = 1 THEN 'ThreeMonth'
										WHEN @SixMonth = 1 THEN 'SixMonth'
										WHEN @Year = 1 THEN 'Year'
									END

	DECLARE @BuilIDMax INT = CASE
								 WHEN @ThreeMonth = 1 THEN 13
								 WHEN @SixMonth = 1 THEN 26
								 WHEN @Year = 1 THEN 52
							 END


	DECLARE @CountBack INT = 0

	DECLARE @StartDate DATE = GETDATE()

	------------------------------------------------------------------------
	-- Clear down intermin table. 
	------------------------------------------------------------------------
	TRUNCATE TABLE [SampleReport].[SampleVolumeBenchmarks]
								
	DELETE
	FROM [SampleReport].[SampleVolumeBenchmarkHistory]
	WHERE CONVERT(DATE, Reportdate) = CONVERT(DATE, GETDATE())
	AND TimePeriod = @Build
	AND BenchmarkType = 'Weekly Calculation'


	------------------------------------------------------------------------
	-- Loops through Build number of weeks
	------------------------------------------------------------------------
	WHILE (@CountBack > -@BuilIDMax)

			BEGIN 
				;WITH FileRowLoadedCountWeek (Brand, Market, Questionnaire, FileRow_LoadedCount)
			AS
				(
				SELECT	L.Brand, 
						M.Market, 
						L.Questionnaire, 
						COUNT(SQ.AuditItemID) AS 'FileRow_LoadedCount'
				FROM [WeeklySampleCheck].[LiveBrandMarketQuestionnaire] L
				INNER JOIN [$(SampleDB)].dbo.Markets M ON L.Market = COALESCE(M.DealerTableEquivMarket, M.Market)
				INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SQ
														ON SQ.Market = M.Market
													AND SQ.Brand = L.Brand  
													AND SQ.Questionnaire = L.Questionnaire
				INNER JOIN [$(AuditDB)].dbo.Files F ON SQ.AuditID = F.AuditID
				WHERE SQ.LoadedDate >= DATEADD(DAY, -7, @StartDate)
				AND SQ.LoadedDate < @StartDate
				AND L.VolumeReportOutput = 1
				GROUP BY L.Brand, M.Market, L.Questionnaire
				)
							
			INSERT INTO [SampleReport].[SampleVolumeBenchmarks] (Market, Brand, Questionnaire, TimePeriod, StartDate, FileRow_LoadedCountWeekly, ReportDate) 
			SELECT	L.Market,
					L.Brand,
					L.Questionnaire,
					(SELECT @Build) AS TimePeriod,
					DATEADD(DAY, -7, @StartDate) AS 'StartDate',
					FRC.FileRow_LoadedCount AS FileRow_LoadedCountWeekly,
					CONVERT(date, GETDATE()) AS 'ReportDate'
			FROM [WeeklySampleCheck].[LiveBrandMarketQuestionnaire] L
			INNER JOIN [$(SampleDB)].dbo.Markets M ON L.Market = COALESCE(M.DealerTableEquivMarket, M.Market)
			LEFT JOIN FileRowLoadedCountWeek FRC ON L.Brand = FRC.Brand
									AND M.Market = FRC.Market
									AND L.Questionnaire = FRC.Questionnaire
			WHERE L.VolumeReportOutput = 1


			SET @StartDate =  DATEADD(DAY, -7, @StartDate) -- PREVIOUS WEEK, MOVING BACKWARDS

		SET @CountBack = @CountBack -1

	END


	------------------------------------------------------------------------
	-- Essentially need to take the top value from the bottom half of the group, and the bottom value of the top half 
	-- of the group, and take an average of the two values.
	-- Source code example https://stackoverflow.com/questions/20566513/how-to-find-the-sql-medians-for-a-grouping
	------------------------------------------------------------------------
	
	;WITH CTE AS
		(   SELECT  Brand,
					Market,
					Questionnaire,
					FileRow_LoadedCountWeekly, 
					[half1] = NTILE(2) OVER(PARTITION BY Brand,Market,Questionnaire ORDER BY FileRow_LoadedCountWeekly), 
					[half2] = NTILE(2) OVER(PARTITION BY Brand,Market,Questionnaire ORDER BY FileRow_LoadedCountWeekly DESC)
			FROM    [SampleReport].[SampleVolumeBenchmarks]
			WHERE   FileRow_LoadedCountWeekly IS NOT NULL
		)
		INSERT INTO	[SampleReport].[SampleVolumeBenchmarkHistory] ([Brand], [Market], [Questionnaire], [TimePeriod], [BenchmarkType], [Median], [ReportDate])
		SELECT  Brand,
				Market,
				Questionnaire,
				(SELECT @Build) AS TimePeriod,
				'Weekly Calculation' AS BenchmarkType,
				CAST(ROUND((MAX(CASE WHEN Half1 = 1 THEN FileRow_LoadedCountWeekly END) + 
				MIN(CASE WHEN Half2 = 1 THEN FileRow_LoadedCountWeekly END)) / 2.0, 0) AS NUMERIC) AS Median,
				CONVERT(date, GETDATE()) AS ReportDate
		FROM    CTE
		GROUP BY Brand, Market, Questionnaire;


	

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
