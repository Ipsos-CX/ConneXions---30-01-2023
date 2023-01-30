CREATE PROCEDURE [SampleReport].[uspDailySampleVolumeCountBMQ]
AS
SET NOCOUNT ON

/*
	Purpose:	Builds daily sample number for current week & previous
			
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
	-- Clear down intermin table. Only leave one historic run per day in [SampleVolumeDailyOutput]
	------------------------------------------------------------------------
	TRUNCATE TABLE [SampleReport].[DailySampleVolumeBMQbyDay]

	TRUNCATE TABLE [SampleReport].[DailySampleVolumeBMQ]

	DELETE
	FROM [SampleReport].[SampleVolumeDailyOutput]
	WHERE CONVERT(DATE, Reportdate) = CONVERT(DATE, GETDATE())


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
		   ('PreviousWeek')



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

		------------------------------------------------------------------------
		-- Set StartDate for each build type
		------------------------------------------------------------------------
		IF @Build = 'PreviousWeek' AND DATENAME(DW,GETDATE()) <> 'Sunday'
			BEGIN
				SET @StartDate = DATEADD(DAY,  2-DATEPART(WEEKDAY, GETDATE()), GETDATE())
			END

		ELSE IF @Build = 'PreviousWeek' AND DATENAME(DW,GETDATE()) = 'Sunday'
			BEGIN
				SET @StartDate = DATEADD(DAY,-6,GETDATE())
			END

		ELSE IF @Build = 'CurrentWeek' AND DATENAME(DW,GETDATE()) <> 'Sunday'
			BEGIN
				SET @StartDate = DATEADD(DAY,  9-DATEPART(WEEKDAY, GETDATE()), GETDATE())
			END

		ELSE IF @Build = 'CurrentWeek' AND DATENAME(DW,GETDATE()) = 'Sunday'
			BEGIN
				SET @StartDate = DATEADD(DAY,1,GETDATE())
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
		-- Summarises Various counts by BMQ + Build Type
		------------------------------------------------------------------------
			INSERT INTO [SampleReport].[DailySampleVolumeBMQbyDay] ([Build],[Brand], [Market], [Questionnaire], [Frequency], [File_Count_Thursday], [FileRow_Count_Thursday], [FileRow_LoadedCount_Thursday], [Selected_Count_Thursday], [File_Count_Wednesday], [FileRow_Count_Wednesday], [FileRow_LoadedCount_Wednesday], [Selected_Count_Wednesday], [File_Count_Tuesday], [FileRow_Count_Tuesday], 
																		   [FileRow_LoadedCount_Tuesday], [Selected_Count_Tuesday], [File_Count_Monday], [FileRow_Count_Monday], [FileRow_LoadedCount_Monday], [Selected_Count_Monday], [File_Count_Sunday], [FileRow_Count_Sunday], [FileRow_LoadedCount_Sunday], [Selected_Count_Sunday], [File_Count_Saturday], [FileRow_Count_Saturday], 
																		   [FileRow_LoadedCount_Saturday], [Selected_Count_Saturday], [File_Count_Friday], [FileRow_Count_Friday], [FileRow_LoadedCount_Friday], [Selected_Count_Friday])
			SELECT  
				A.Build,
				A.Brand,
				A.Market,
				A.Questionnaire,
				A.Frequency,
				A.[Thursday] AS [File_Count_Thursday], 
				B.[Thursday] AS [FileRow_Count_Thursday],
				C.[Thursday] AS [FileRow_LoadedCount_Thursday],
				D.[Thursday] AS [Selected_Count_Thursday],

				A.[Wednesday] AS [File_Count_Wednesday], 
				B.[Wednesday] AS [FileRow_Count_Wednesday],
				C.[Wednesday] AS [FileRow_LoadedCount_Wednesday],
				D.[Wednesday] AS [Selected_Count_Wednesday],

				A.[Tuesday] AS [File_Count_Tuesday], 
				B.[Tuesday] AS [FileRow_Count_Tuesday],
				C.[Tuesday] AS [FileRow_LoadedCount_Tuesday],
				D.[Tuesday] AS [Selected_Count_Tuesday],

				A.[Monday] AS [File_Count_Monday], 
				B.[Monday] AS [FileRow_Count_Monday],
				C.[Monday] AS [FileRow_LoadedCount_Monday],
				D.[Monday] AS [Selected_Count_Monday],

				A.[Sunday] AS [File_Count_Sunday], 
				B.[Sunday] AS [FileRow_Count_Sunday],
				C.[Sunday] AS [FileRow_LoadedCount_Sunday],
				D.[Sunday] AS [Selected_Count_Sunday],

				A.[Saturday] AS [File_Count_Saturday], 
				B.[Saturday] AS [FileRow_Count_Saturday],
				C.[Saturday] AS [FileRow_LoadedCount_Saturday],
				D.[Saturday] AS [Selected_Count_Saturday],

				A.[Friday] AS [File_Count_Friday], 
				B.[Friday] AS [FileRow_Count_Friday],
				C.[Friday] AS [FileRow_LoadedCount_Friday],
				D.[Friday] AS [Selected_Count_Friday]

			FROM

			(SELECT * FROM (
			 SELECT
				Build,
				Brand,
				Market,
				Questionnaire,
				Frequency,
				File_Count,
				datename(dw,ResultDate) AS DayText

			FROM [SampleReport].[DailySampleVolumeBMQ]

			) Results
			PIVOT (
			  SUM([File_Count])
			  FOR [DayText]
			  IN (
				[Thursday],
				[Wednesday],
				[Tuesday],
				[Monday],
				[Sunday],
				[Saturday],
				[Friday]
			  )
			) AS A) A

			FULL JOIN

			(SELECT * FROM (
			 SELECT
				Build,
				Brand,
				Market,
				Questionnaire,
				FileRow_Count,
				datename(dw,ResultDate) AS DayText

			FROM [SampleReport].[DailySampleVolumeBMQ]

			) Results
			PIVOT (
			  SUM([FileRow_Count])
			  FOR [DayText]
			  IN (
				[Thursday],
				[Wednesday],
				[Tuesday],
				[Monday],
				[Sunday],
				[Saturday],
				[Friday]
			  )
			) AS B) B

			ON A.Brand = B.Brand
			AND A.Market = B.Market
			AND A.Questionnaire = B.Questionnaire
			AND A.Build = B.Build

			FULL JOIN

			(SELECT * FROM (
			 SELECT
				Build,
				Brand,
				Market,
				Questionnaire,
				FileRow_LoadedCount,
				datename(dw,ResultDate) AS DayText

			FROM [SampleReport].[DailySampleVolumeBMQ]

			) Results
			PIVOT (
			  SUM([FileRow_LoadedCount])
			  FOR [DayText]
			  IN (
				[Thursday],
				[Wednesday],
				[Tuesday],
				[Monday],
				[Sunday],
				[Saturday],
				[Friday]
			  )
			) AS C) C

			ON A.Brand = C.Brand
			AND A.Market = C.Market
			AND A.Questionnaire = C.Questionnaire
			AND A.Build = C.Build

			FULL JOIN

			(SELECT * FROM (
			 SELECT
				Build,
				Brand,
				Market,
				Questionnaire,
				Selected_Count,
				datename(dw,ResultDate) AS DayText

			FROM [SampleReport].[DailySampleVolumeBMQ]

			) Results
			PIVOT (
			  SUM([Selected_Count])
			  FOR [DayText]
			  IN (
				[Thursday],
				[Wednesday],
				[Tuesday],
				[Monday],
				[Sunday],
				[Saturday],
				[Friday]
			  )
			) AS D) D

			ON A.Brand = D.Brand
			AND A.Market = D.Market
			AND A.Questionnaire = D.Questionnaire
			AND A.Build = D.Build
	
		------------------------------------------------------------------------
		-- Update Totals & Report Date
		------------------------------------------------------------------------
			UPDATE WS
			SET WS.WeekTotal =  COALESCE([FileRow_LoadedCount_Monday],0) + 
								COALESCE([FileRow_LoadedCount_Tuesday],0) + 
								COALESCE([FileRow_LoadedCount_Wednesday],0) + 
								COALESCE([FileRow_LoadedCount_Thursday],0) + 
								COALESCE([FileRow_LoadedCount_Friday],0) + 
								COALESCE([FileRow_LoadedCount_Saturday],0) +
								COALESCE([FileRow_LoadedCount_Sunday],0),
				 WS.ReportDate = CONVERT(date, GETDATE())
			FROM [SampleReport].[DailySampleVolumeBMQbyDay] WS

	------------------------------------------------------------------------
		-- Load results into table. Included headers to output. This Table holds Historic runs
		-- File count, File Row count & Selected count available to ouput in future.
	------------------------------------------------------------------------
	;WITH CurrentWeek
			(
				   Brand,
				   Market,
				   Questionnaire,
				   Frequency,

				   File_Count_Monday,
				   FileRow_Count_Monday,
				   FileRow_LoadedCount_Monday,
				   Selected_Count_Monday,

				   File_Count_Tuesday,
				   FileRow_Count_Tuesday,
				   FileRow_LoadedCount_Tuesday,
				   Selected_Count_Tuesday,

				   File_Count_Wednesday,
				   FileRow_Count_Wednesday,
				   FileRow_LoadedCount_Wednesday,
				   Selected_Count_Wednesday,

				   File_Count_Thursday,
				   FileRow_Count_Thursday,
				   FileRow_LoadedCount_Thursday,
				   Selected_Count_Thursday,

				   File_Count_Friday,
				   FileRow_Count_Friday,
				   FileRow_LoadedCount_Friday,
				   Selected_Count_Friday,

				   File_Count_Saturday,
				   FileRow_Count_Saturday,
				   FileRow_LoadedCount_Saturday,
				   Selected_Count_Saturday,

				   File_Count_Sunday,
				   FileRow_Count_Sunday,
				   FileRow_LoadedCount_Sunday,
				   Selected_Count_Sunday,

				   WeekTotal,
				   ReportDate
		)
	AS
		(
			SELECT Brand,
				   Market,
				   Questionnaire,
				   Frequency,

				   File_Count_Monday,
				   FileRow_Count_Monday,
				   FileRow_LoadedCount_Monday,
				   Selected_Count_Monday,

				   File_Count_Tuesday,
				   FileRow_Count_Tuesday,
				   FileRow_LoadedCount_Tuesday,
				   Selected_Count_Tuesday,

				   File_Count_Wednesday,
				   FileRow_Count_Wednesday,
				   FileRow_LoadedCount_Wednesday,
				   Selected_Count_Wednesday,

				   File_Count_Thursday,
				   FileRow_Count_Thursday,
				   FileRow_LoadedCount_Thursday,
				   Selected_Count_Thursday,

				   File_Count_Friday,
				   FileRow_Count_Friday,
				   FileRow_LoadedCount_Friday,
				   Selected_Count_Friday,

				   File_Count_Saturday,
				   FileRow_Count_Saturday,
				   FileRow_LoadedCount_Saturday,
				   Selected_Count_Saturday,

				   File_Count_Sunday,
				   FileRow_Count_Sunday,
				   FileRow_LoadedCount_Sunday,
				   Selected_Count_Sunday,

				   WeekTotal,
				   ReportDate
			FROM [SampleReport].[DailySampleVolumeBMQbyDay]
			WHERE Build = 'CurrentWeek'
		),
	PreviousWeek (Brand, Market, Questionnaire, PreviousWeekDayCount, WeekTotal, ReportDate)
	AS
		(	
			SELECT Brand,
				   Market,
				   Questionnaire,
				   CASE 
						WHEN DATENAME(dw,GETDATE()) = 'Monday' THEN FileRow_LoadedCount_Monday
						WHEN DATENAME(dw,GETDATE()) = 'Tuesday' THEN FileRow_LoadedCount_Tuesday
						WHEN DATENAME(dw,GETDATE()) = 'Wednesday' THEN FileRow_LoadedCount_Wednesday
						WHEN DATENAME(dw,GETDATE()) = 'Thursday' THEN FileRow_LoadedCount_Thursday
						WHEN DATENAME(dw,GETDATE()) = 'Friday' THEN FileRow_LoadedCount_Friday
						WHEN DATENAME(dw,GETDATE()) = 'Saturday' THEN FileRow_LoadedCount_Saturday
						WHEN DATENAME(dw,GETDATE()) = 'Sunday' THEN FileRow_LoadedCount_Sunday
					END AS PreviousWeekDayCount,

					WeekTotal,
					ReportDate

			FROM [SampleReport].[DailySampleVolumeBMQbyDay]
			WHERE Build = 'PreviousWeek'
		)
			INSERT INTO [SampleReport].[SampleVolumeDailyOutput] (HeaderID, Brand, Market, Questionnaire, Frequency, BenchMark, FileRow_LoadedCount_Monday, FileRow_LoadedCount_Tuesday, FileRow_LoadedCount_Wednesday, FileRow_LoadedCount_Thursday, FileRow_LoadedCount_Friday, FileRow_LoadedCount_Saturday, FileRow_LoadedCount_Sunday, PreviousWeekDayCount, CurrentWkTotal, PreviousWkTotal, ReportDate)
			SELECT DISTINCT
					0 AS HeaderID,
					ISNULL(CAST(WS.Brand AS [nvarchar](255)),0),
					ISNULL(CAST(WS.Market AS [nvarchar](255)),0),
					ISNULL(CAST(WS.Questionnaire AS [nvarchar](255)),0),
					ISNULL(CAST(WS.Frequency AS [nvarchar](255)),0),
					CAST(LV.MedianDaily AS [nvarchar](255)) AS [BenchMark],
					ISNULL(CAST(CW.FileRow_LoadedCount_Monday AS [nvarchar](255)),0),
					ISNULL(CAST(CW.FileRow_LoadedCount_Tuesday AS [nvarchar](255)),0),
					ISNULL(CAST(CW.FileRow_LoadedCount_Wednesday AS [nvarchar](255)),0),
					ISNULL(CAST(CW.FileRow_LoadedCount_Thursday AS [nvarchar](255)),0),
					ISNULL(CAST(CW.FileRow_LoadedCount_Friday AS [nvarchar](255)),0),
					ISNULL(CAST(CW.FileRow_LoadedCount_Saturday AS [nvarchar](255)),0),
					ISNULL(CAST(CW.FileRow_LoadedCount_Sunday AS [nvarchar](255)),0),

					ISNULL(CAST(PW.PreviousWeekDayCount AS [nvarchar](255)),0),

					ISNULL(CAST(CW.WeekTotal AS [nvarchar](255)),0) AS CurrentWkTotal,
					ISNULL(CAST(PW.WeekTotal AS [nvarchar](255)),0) AS PreviousWkTotal,

					CW.ReportDate
			
			FROM [SampleReport].[DailySampleVolumeBMQbyDay] WS
			LEFT JOIN [WeeklySampleCheck].[LiveBrandMarketQuestionnaire] LV ON WS.Market = LV.Market
																    AND WS.Brand = LV.Brand
																	AND WS.Questionnaire = LV.Questionnaire
			LEFT JOIN CurrentWeek CW ON WS.Brand = CW.Brand
									AND WS.Market = CW.Market
									AND WS.Questionnaire = CW.Questionnaire
			LEFT JOIN PreviousWeek PW ON WS.Brand = PW.Brand
									AND WS.Market = PW.Market
									AND WS.Questionnaire = PW.Questionnaire

		UNION ALL

		SELECT		
					1 AS HeaderID,
					'Brand' AS Brand,
					'Market' AS Market,
					'Questionnaire' AS Questionnaire,
					'Frequency' AS Frequency,
					'Bench Mark' AS BenchMark,
					'Monday' AS FileRow_LoadedCount_Monday,
					'Tuesday' AS FileRow_LoadedCount_Tuesday,
					'Wednesday' AS FileRow_LoadedCount_Wednesday,
					'Thursday'AS FileRow_LoadedCount_Thursday,
					'Friday'AS FileRow_LoadedCount_Friday,
					'Saturday 'AS FileRow_LoadedCount_Saturday,
					'Sunday' AS FileRow_LoadedCount_Sunday,

					'Previous ' + DATENAME(weekday,GETDATE()) AS PreviousWeekDayCount,

					'WeekTotal' AS CurrentWkTotal,
					'Previous Week Total' AS PreviousWkTotal,
					GETDATE() AS ReportDate
	

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

