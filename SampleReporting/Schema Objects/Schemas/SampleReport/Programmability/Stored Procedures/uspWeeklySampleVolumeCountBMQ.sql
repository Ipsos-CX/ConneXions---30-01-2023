CREATE PROCEDURE [SampleReport].[uspWeeklySampleVolumeCountBMQ]
AS
SET NOCOUNT ON

/*
	Purpose:	Builds Weekly sample number for current week & previous 4 Weeks
			
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
	-- Clear down intermin table. Only leave one historic run per day in [SampleVolumeWeeklyOutput]
	------------------------------------------------------------------------

	TRUNCATE TABLE [SampleReport].[DailySampleVolumeBMQ]

	DELETE
	FROM [SampleReport].[SampleVolumeWeeklyOutput]
	WHERE CONVERT(DATE, ReportDate) = CONVERT(DATE, GETDATE())

	------------------------------------------------------------------------
	-- Drop and build meta.temp_build_types
	------------------------------------------------------------------------
	DROP TABLE IF EXISTS #temp_build_types;

	CREATE TABLE #temp_build_types
	(
		ID TINYINT IDENTITY (1, 1),
		Build VARCHAR (20)
	)	
	------------------------------------------------------------------------
	-- New BuildTypes require @StartDate code updating below
	------------------------------------------------------------------------
	INSERT INTO #temp_build_types (Build)
	VALUES ('CurrentWeek'),
		   ('WeekMinus1'),
		   ('WeekMinus2'),
		   ('WeekMinus3'),
		   ('WeekMinus4')

	DECLARE @Build VARCHAR (20)

	DECLARE @BuilID INT = 1

	DECLARE @BuilIDMax INT = (SELECT MAX(ID) FROM #temp_build_types)

	------------------------------------------------------------------------
	-- Outter most loop. Sets Build Type & Dates. Loops Build Type
	------------------------------------------------------------------------
	WHILE (@BuilID <= @BuilIDMax)
	BEGIN

		SET @Build = (SELECT Build FROM #temp_build_types WHERE ID = @BuilID)
		
		DECLARE @StartDate DATETIME
		DECLARE @CountBack INT = 0


		--Sets Saturdy as first day of week. Runs Saturday - Fridays (full week)
		SET DATEFIRST 5

		------------------------------------------------------------------------
		-- Set StartDate for each build type
		------------------------------------------------------------------------
		IF @Build = 'CurrentWeek'
			BEGIN
				SET @StartDate = DATEADD(wk, DATEDIFF(wk, 5, GETDATE()), 5)
			END

		ELSE IF @Build = 'WeekMinus1'
			BEGIN
				SET @StartDate = DATEADD(DAY, -7, DATEADD(wk, DATEDIFF(wk, 5, GETDATE()), 5))
			END

		ELSE IF @Build = 'WeekMinus2'
			BEGIN
				SET @StartDate = DATEADD(DAY, -14, DATEADD(wk, DATEDIFF(wk, 5, GETDATE()), 5))
			END

		ELSE IF @Build = 'WeekMinus3'
			BEGIN
				SET @StartDate = DATEADD(DAY, -21, DATEADD(wk, DATEDIFF(wk, 5, GETDATE()), 5))
			END

		ELSE IF @Build = 'WeekMinus4'
			BEGIN
				SET @StartDate = DATEADD(DAY, -28, DATEADD(wk, DATEDIFF(wk, 5, GETDATE()), 5))
			END
		
				------------------------------------------------------------------------
				-- Inner loop. Loops through Startdate 7 day weekly period for each Build Type
				------------------------------------------------------------------------
				WHILE (@CountBack > -7)

						BEGIN 
						;WITH FileCount (Brand, Market, Questionnaire, File_Count)
						AS
							(
							SELECT	L.Brand, 
									M.Market, 
									L.Questionnaire, 
									COUNT(DISTINCT F.FileName) AS 'File_Count'
							FROM [WeeklySampleCheck].[LiveBrandMarketQuestionnaire] L
							INNER JOIN [$(SampleDB)].dbo.Markets M ON L.Market = COALESCE(M.DealerTableEquivMarket, M.Market)
							INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SQ
																 ON SQ.Market = M.Market
																AND SQ.Brand = L.Brand  
																AND SQ.Questionnaire = L.Questionnaire
							INNER JOIN [$(AuditDB)].dbo.Files F ON SQ.AuditID = F.AuditID
							WHERE SQ.LoadedDate >= DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack - 1)
							AND SQ.LoadedDate < DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack)
							AND L.VolumeReportOutput = 1
							GROUP BY L.Brand, M.Market, L.Questionnaire
							)
							,
							FileRowCount_1 (Brand, Market, Questionnaire, FileRowCount, FileName)
						AS
							(
							SELECT DISTINCT	L.Brand, 
											M.Market, 
											L.Questionnaire, 
											F.FileRowCount,
											F.FileName
							FROM [WeeklySampleCheck].[LiveBrandMarketQuestionnaire] L
							INNER JOIN [$(SampleDB)].dbo.Markets M ON L.Market = COALESCE(M.DealerTableEquivMarket, M.Market)
							INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SQ
																 ON SQ.Market = M.Market
																AND SQ.Brand = L.Brand  
																AND SQ.Questionnaire = L.Questionnaire
							INNER JOIN [$(AuditDB)].dbo.Files F ON SQ.AuditID = F.AuditID
							WHERE SQ.LoadedDate >= DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack - 1)
							AND SQ.LoadedDate < DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack)
							AND L.VolumeReportOutput = 1
							)
							,
							FileRowCount_2 (Brand, Market, Questionnaire, FileRow_Count)
						AS
							(
							SELECT DISTINCT	Brand, 
											Market, 
											Questionnaire, 
											SUM(CAST(FileRowCount AS BIGINT)) AS 'FileRow_Count'
							FROM FileRowCount_1
							GROUP BY Brand, Market, Questionnaire
							),
							FileRowLoadedCount (Brand, Market, Questionnaire, FileRow_LoadedCount)
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
							WHERE SQ.LoadedDate >= DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack - 1)
							AND SQ.LoadedDate < DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack)
							AND L.VolumeReportOutput = 1
							GROUP BY L.Brand, M.Market, L.Questionnaire
							)
							,
							SelectedCount (Brand, Market, Questionnaire, Selected_Count)
						AS
							(
							SELECT	L.Brand, 
									M.Market, 
									L.Questionnaire, 
									COUNT(DISTINCT SQ.CaseID) AS 'Selected_Count'
							FROM [WeeklySampleCheck].[LiveBrandMarketQuestionnaire] L
							INNER JOIN [$(SampleDB)].dbo.Markets M ON L.Market = COALESCE(M.DealerTableEquivMarket, M.Market)
							INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SQ
																 ON SQ.Market = M.Market
																AND SQ.Brand = L.Brand  
																AND SQ.Questionnaire = L.Questionnaire
							INNER JOIN [$(AuditDB)].dbo.Files F ON SQ.AuditID = F.AuditID
							WHERE SQ.LoadedDate >= DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack - 1)
							AND SQ.LoadedDate < DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack)
							AND SQ.CaseID IS NOT NULL
							AND L.VolumeReportOutput = 1
							GROUP BY L.Brand, M.Market, L.Questionnaire
							)

						INSERT INTO [SampleReport].[DailySampleVolumeBMQ] (Build,Market, Brand, Questionnaire, Frequency, File_Count, FileRow_Count, FileRow_LoadedCount, Selected_Count, ResultDate, ReportDate)
						SELECT	(SELECT @Build) AS Build,
								L.Market,
								L.Brand,
								L.Questionnaire,
								L.Frequency,
								FC.File_Count,
								FR.FileRow_Count,
								FRC.FileRow_LoadedCount,
								S.Selected_Count,
								DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack - 1) AS 'ResultDate',
								CONVERT(date, GETDATE()) AS 'ReportDate'
						FROM [WeeklySampleCheck].[LiveBrandMarketQuestionnaire] L
						INNER JOIN [$(SampleDB)].dbo.Markets M ON L.Market = COALESCE(M.DealerTableEquivMarket, M.Market)
						LEFT JOIN FileCount FC ON L.Brand = FC.Brand
											  AND M.Market = FC.Market
											  AND L.Questionnaire = FC.Questionnaire
						LEFT JOIN FileRowCount_2 FR ON L.Brand = FR.Brand
											  AND M.Market = FR.Market
											  AND L.Questionnaire = FR.Questionnaire
						LEFT JOIN FileRowLoadedCount FRC ON L.Brand = FRC.Brand
											  AND M.Market = FRC.Market
											  AND L.Questionnaire = FRC.Questionnaire
						LEFT JOIN SelectedCount S ON L.Brand = S.Brand
											  AND M.Market = S.Market
											  AND L.Questionnaire = S.Questionnaire
						WHERE L.VolumeReportOutput = 1

					SET @CountBack = @CountBack -1

				END

			SET @BuilID = @BuilID + 1
	END


	------------------------------------------------------------------------
	-- Summarise weekly counts and add dynamic/static headers for output
	-------------------------------------------------------------------------
	;WITH CurrentWeekCount (Brand, Market, Questionnaire, LoadedCount)
		AS
			(
				SELECT 
					Brand,
					Market,
					Questionnaire,
					SUM(FileRow_LoadedCount) AS LoadedCount
				FROM [SampleReport].[DailySampleVolumeBMQ]
				WHERE Build = 'CurrentWeek'
				GROUP BY Brand, Market, Questionnaire
			),
		WeekMinus1 (Brand, Market, Questionnaire, LoadedCount)
		AS
			(
				SELECT 
					Brand,
					Market,
					Questionnaire,
					SUM(FileRow_LoadedCount) AS LoadedCount
				FROM [SampleReport].[DailySampleVolumeBMQ]
				WHERE Build = 'WeekMinus1'
				GROUP BY Brand, Market, Questionnaire
			),
		WeekMinus2 (Brand, Market, Questionnaire, LoadedCount)
		AS
			(
				SELECT 
					Brand,
					Market,
					Questionnaire,
					SUM(FileRow_LoadedCount) AS LoadedCount
				FROM [SampleReport].[DailySampleVolumeBMQ]
				WHERE Build = 'WeekMinus2'
				GROUP BY Brand, Market, Questionnaire
			),
		WeekMinus3 (Brand, Market, Questionnaire, LoadedCount)
		AS
			(
				SELECT 
					Brand,
					Market,
					Questionnaire,
					SUM(FileRow_LoadedCount) AS LoadedCount
				FROM [SampleReport].[DailySampleVolumeBMQ]
				WHERE Build = 'WeekMinus3'
				GROUP BY Brand, Market, Questionnaire
			),
		WeekMinus4 (Brand, Market, Questionnaire, LoadedCount)
		AS
			(
				SELECT 
					Brand,
					Market,
					Questionnaire,
					SUM(FileRow_LoadedCount) AS LoadedCount
				FROM [SampleReport].[DailySampleVolumeBMQ]
				WHERE Build = 'WeekMinus4'
				GROUP BY Brand, Market, Questionnaire
			),
		CurrentMonth (Brand, Market, Questionnaire, LoadedCount)
		AS
			(
				SELECT 
					Brand,
					Market,
					Questionnaire,
					SUM(FileRow_LoadedCount) AS LoadedCount
				FROM [SampleReport].[DailySampleVolumeBMQ]
				WHERE MONTH(ResultDate) = MONTH(GETDATE())
				GROUP BY Brand, Market, Questionnaire
			)
		INSERT INTO [SampleReport].[SampleVolumeWeeklyOutput] (HeaderID, Brand, Market, Questionnaire, Frequency, BenchMark, CurrentWeekLoaded, WeekMinus1Loaded, WeekMinus2Loaded, WeekMinus3Loaded, WeekMinus4Loaded, MonthTotal, ReportDate)
		SELECT DISTINCT
			0 AS HeaderID,
			ISNULL(CAST(DV.Brand AS [nvarchar](255)),0) AS Brand,
			ISNULL(CAST(DV.Market AS [nvarchar](255)),0) AS Market,
			ISNULL(CAST(DV.Questionnaire AS [nvarchar](255)),0) AS Questionnaire,
			ISNULL(CAST(DV.Frequency AS [nvarchar](255)),0) AS Frequency,
			CAST(LV.MedianWeekly AS [nvarchar](255)) AS [BenchMark],
			ISNULL(CAST(CW.LoadedCount AS [nvarchar](255)),0) AS 'CurrentWeekLoaded',
			ISNULL(CAST(W1.LoadedCount AS [nvarchar](255)),0) AS 'WeekMinus1Loaded',
			ISNULL(CAST(W2.LoadedCount AS [nvarchar](255)),0) AS 'WeekMinus2Loaded',
			ISNULL(CAST(W3.LoadedCount AS [nvarchar](255)),0) AS 'WeekMinus3Loaded',
			ISNULL(CAST(W4.LoadedCount AS [nvarchar](255)),0) AS 'WeekMinus4Loaded',
			ISNULL(CAST(CM.LoadedCount AS [nvarchar](255)),0) AS 'MonthTotal',
			CONVERT(date, GETDATE()) AS ReportDate
		FROM [SampleReport].[DailySampleVolumeBMQ] DV
		LEFT JOIN CurrentWeekCount CW ON DV.Brand = CW.Brand			
									 AND DV.Questionnaire =  CW.Questionnaire
									 AND DV.Market = CW.Market
		LEFT JOIN WeekMinus1 W1 ON DV.Brand = W1.Brand			
									 AND DV.Questionnaire =  W1.Questionnaire
									 AND DV.Market = W1.Market
		LEFT JOIN WeekMinus2 W2 ON DV.Brand = W2.Brand			
									 AND DV.Questionnaire =  W2.Questionnaire
									 AND DV.Market = W2.Market
		LEFT JOIN WeekMinus3 W3 ON DV.Brand = W3.Brand			
									 AND DV.Questionnaire =  W3.Questionnaire
									 AND DV.Market = W3.Market
		LEFT JOIN WeekMinus4 W4 ON DV.Brand = W4.Brand			
									 AND DV.Questionnaire =  W4.Questionnaire
									 AND DV.Market = W4.Market
		LEFT JOIN CurrentMonth CM ON DV.Brand = CM.Brand			
									 AND DV.Questionnaire =  CM.Questionnaire
									 AND DV.Market = CM.Market
		LEFT JOIN [WeeklySampleCheck].[LiveBrandMarketQuestionnaire] LV ON DV.Market = LV.Market
																    AND DV.Brand = LV.Brand
																	AND DV.Questionnaire = LV.Questionnaire
		UNION

		SELECT
			1 AS HeaderID,
			'Brand' AS Brand,
			'Market' AS Market,
			'Questionnaire' AS Questionnaire,
			'Frequency' AS Frequency,
			'Bench Mark' AS BenchMark,
			(SELECT 'Week Ending ' + CAST(MAX(CONVERT(DATE,ResultDate)) AS NVARCHAR (20)) FROM [SampleReport].[DailySampleVolumeBMQ]) AS 'CurrentWeekLoaded' ,
			'-1 week' AS WeekMinus1Loaded,
			'-2 week' AS WeekMinus2Loaded,
			'-3 week' AS WeekMinus3Loaded,
			'-4 week' AS WeekMinus4Loaded,
			(SELECT DATENAME(MM, GETDATE())) + ' Total' AS 'MonthTotal',
			CONVERT(date, GETDATE()) AS ReportDate

		ORDER BY HeaderID desc


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
