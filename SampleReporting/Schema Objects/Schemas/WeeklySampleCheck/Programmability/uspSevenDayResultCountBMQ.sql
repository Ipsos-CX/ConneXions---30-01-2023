CREATE PROCEDURE [WeeklySampleCheck].[uspSevenDayResultCountBMQ]
AS
SET NOCOUNT ON

/*
	Purpose:	Report Sample Loaded numbers weekly, FRIDAY
			
	Version			Date			Developer			Comment
	1.0				21/05/2021		Ben King			TASK 450
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY

	    DECLARE @StartDate DATETIME
	 
		DECLARE @CountBack INT
		SET @CountBack = 0
		SET @StartDate = DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 1)


		TRUNCATE TABLE [WeeklySampleCheck].[SevenDayResultCountBMQ]

		TRUNCATE TABLE [WeeklySampleCheck].[SevenDayResultCountBMQbyDay]


	WHILE (@CountBack > -7)

			BEGIN 
			;WITH FileCount (Brand, Market, Questionnaire, File_Count)
			AS
				(
				SELECT 
					L.Brand, 
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
				WHERE F.ActionDate >= DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack - 1)
				AND F.ActionDate < DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack)
				GROUP BY L.Brand, M.Market, L.Questionnaire
				)
				,
				FileRowCount_1 (Brand, Market, Questionnaire, FileRowCount, FileName)
			AS
				(
				SELECT DISTINCT
					L.Brand, 
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
				WHERE F.ActionDate >= DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack - 1)
				AND F.ActionDate < DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack)
				)
				,
				FileRowCount_2 (Brand, Market, Questionnaire, FileRow_Count)
			AS
				(
				SELECT DISTINCT
					Brand, 
					Market, 
					Questionnaire, 
					SUM(CAST(FileRowCount AS BIGINT)) AS 'FileRow_Count'
				FROM FileRowCount_1
				GROUP BY Brand, Market, Questionnaire
				),
				FileRowLoadedCount (Brand, Market, Questionnaire, FileRow_LoadedCount)
			AS
				(
				SELECT 
					L.Brand, 
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
				WHERE F.ActionDate >= DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack - 1)
				AND F.ActionDate < DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack)
				GROUP BY L.Brand, M.Market, L.Questionnaire
				)
				,
				SelectedCount (Brand, Market, Questionnaire, Selected_Count)
			AS
				(
				SELECT 
					L.Brand, 
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
				WHERE F.ActionDate >= DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack - 1)
				AND F.ActionDate < DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack)
				AND SQ.CaseID IS NOT NULL
				GROUP BY L.Brand, M.Market, L.Questionnaire
				)

			INSERT INTO [WeeklySampleCheck].[SevenDayResultCountBMQ] (Market, Brand, Questionnaire, Frequency, File_Count, FileRow_Count, FileRow_LoadedCount, Selected_Count, ResultDay)
			SELECT 
				L.Market,
				L.Brand,
				L.Questionnaire,
				L.Frequency,
				FC.File_Count,
				FR.FileRow_Count,
				FRC.FileRow_LoadedCount,
				S.Selected_Count,
				DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack - 1) AS 'ResultDay'
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

			SET @CountBack = @CountBack -1

	END


	--SUMMARISE COUNTS BY DAY
	INSERT INTO [WeeklySampleCheck].[SevenDayResultCountBMQbyDay] ([Brand], [Market], [Questionnaire], [Frequency], [File_Count - Thursday], [FileRow_Count - Thursday], [FileRow_LoadedCount - Thursday], [Selected_Count - Thursday], [File_Count - Wednesday], [FileRow_Count - Wednesday], [FileRow_LoadedCount - Wednesday], [Selected_Count - Wednesday], [File_Count - Tuesday], [FileRow_Count - Tuesday], 
																   [FileRow_LoadedCount - Tuesday], [Selected_Count - Tuesday], [File_Count - Monday], [FileRow_Count - Monday], [FileRow_LoadedCount - Monday], [Selected_Count - Monday], [File_Count - Sunday], [FileRow_Count - Sunday], [FileRow_LoadedCount - Sunday], [Selected_Count - Sunday], [File_Count - Saturday], [FileRow_Count - Saturday], 
																   [FileRow_LoadedCount - Saturday], [Selected_Count - Saturday], [File_Count - Friday], [FileRow_Count - Friday], [FileRow_LoadedCount - Friday], [Selected_Count - Friday])
	SELECT 
		A.Brand, 
		A.Market,
		A.Questionnaire,
		A.Frequency,
		A.[Thursday] AS [File_Count - Thursday], 
		B.[Thursday] AS [FileRow_Count - Thursday],
		C.[Thursday] AS [FileRow_LoadedCount - Thursday],
		D.[Thursday] AS [Selected_Count - Thursday],

		A.[Wednesday] AS [File_Count - Wednesday], 
		B.[Wednesday] AS [FileRow_Count - Wednesday],
		C.[Wednesday] AS [FileRow_LoadedCount - Wednesday],
		D.[Wednesday] AS [Selected_Count - Wednesday],

		A.[Tuesday] AS [File_Count - Tuesday], 
		B.[Tuesday] AS [FileRow_Count - Tuesday],
		C.[Tuesday] AS [FileRow_LoadedCount - Tuesday],
		D.[Tuesday] AS [Selected_Count - Tuesday],

		A.[Monday] AS [File_Count - Monday], 
		B.[Monday] AS [FileRow_Count - Monday],
		C.[Monday] AS [FileRow_LoadedCount - Monday],
		D.[Monday] AS [Selected_Count - Monday],

		A.[Sunday] AS [File_Count - Sunday], 
		B.[Sunday] AS [FileRow_Count - Sunday],
		C.[Sunday] AS [FileRow_LoadedCount - Sunday],
		D.[Sunday] AS [Selected_Count - Sunday],

		A.[Saturday] AS [File_Count - Saturday], 
		B.[Saturday] AS [FileRow_Count - Saturday],
		C.[Saturday] AS [FileRow_LoadedCount - Saturday],
		D.[Saturday] AS [Selected_Count - Saturday],

		A.[Friday] AS [File_Count - Friday], 
		B.[Friday] AS [FileRow_Count - Friday],
		C.[Friday] AS [FileRow_LoadedCount - Friday],
		D.[Friday] AS [Selected_Count - Friday]
		
	FROM

	(SELECT * FROM (
	 SELECT
		Brand,
		Market,
		Questionnaire,
		Frequency,
		File_Count,
		datename(dw,ResultDay) AS DayText

	FROM [WeeklySampleCheck].[SevenDayResultCountBMQ]

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
		Brand,
		Market,
		Questionnaire,
		FileRow_Count,
		datename(dw,ResultDay) AS DayText

	FROM [WeeklySampleCheck].[SevenDayResultCountBMQ]

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

	FULL JOIN

	(SELECT * FROM (
	 SELECT
		Brand,
		Market,
		Questionnaire,
		FileRow_LoadedCount,
		datename(dw,ResultDay) AS DayText

	FROM [WeeklySampleCheck].[SevenDayResultCountBMQ]

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

	FULL JOIN

	(SELECT * FROM (
	 SELECT
		Brand,
		Market,
		Questionnaire,
		Selected_Count,
		datename(dw,ResultDay) AS DayText

	FROM [WeeklySampleCheck].[SevenDayResultCountBMQ]

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

