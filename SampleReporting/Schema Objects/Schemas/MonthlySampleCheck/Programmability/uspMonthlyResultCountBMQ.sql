CREATE PROCEDURE [MonthlySampleCheck].[uspMonthlyResultCountBMQ]
AS
SET NOCOUNT ON

/*
	Purpose:	Report Sample Loaded numbers - Monthly aggregates
			
	Version			Date			Developer			Comment
	1.0				21/05/2021		Ben King			TASK 518
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY

	    DECLARE @StartDate DATETIME, @CQIStartDate DATETIME
	 
		DECLARE @CountMonth INT, @NoMonths AS INT

		SET @CountMonth = 0
		
		SET @CQIStartDate = '2021-04-01' -- JLR RE-LAUNCH

		SET @NoMonths = DATEDIFF(MONTH, @CQIStartDate, GETDATE()) + 1 --NO. OF MONTHS TO LOOP SINCE LAUNCH DATE


		TRUNCATE TABLE [MonthlySampleCheck].[MonthlyResultCountBMQ]


	WHILE (@CountMonth < @NoMonths)

			BEGIN 

			SET @StartDate = DATEADD(month, @CountMonth, @CQIStartDate)

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
				WHERE F.ActionDate >= @StartDate
				AND F.ActionDate < DATEADD(month, 1, @StartDate)
				AND L.Questionnaire LIKE '%CQI%'
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
				WHERE F.ActionDate >= @StartDate
				AND F.ActionDate < DATEADD(month, 1, @StartDate)
				AND L.Questionnaire LIKE '%CQI%'
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
				WHERE F.ActionDate >= @StartDate
				AND F.ActionDate < DATEADD(month, 1, @StartDate)
				AND L.Questionnaire LIKE '%CQI%'
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
				WHERE F.ActionDate >= @StartDate
				AND F.ActionDate < DATEADD(month, 1, @StartDate)
				AND SQ.CaseID IS NOT NULL
				AND L.Questionnaire LIKE '%CQI%'
				GROUP BY L.Brand, M.Market, L.Questionnaire
				)

			INSERT INTO [MonthlySampleCheck].[MonthlyResultCountBMQ] (Market, Brand, Questionnaire, Frequency, File_Count, FileRow_Count, FileRow_LoadedCount, Selected_Count, ResultMonth, ResultYear, ResultDate)
			SELECT DISTINCT
				L.Market,
				L.Brand,
				L.Questionnaire,
				L.Frequency,
				FC.File_Count,
				FR.FileRow_Count,
				FRC.FileRow_LoadedCount,
				S.Selected_Count,
				DATENAME(MONTH,DATEADD(mm, DATEDIFF(mm, 0, @StartDate), @CountMonth)) AS 'ResultMonth',
				YEAR(@StartDate) AS 'ResultYear',
				@StartDate AS 'ResultDate'
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

			SET @CountMonth = @CountMonth + 1

	END


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


GO
