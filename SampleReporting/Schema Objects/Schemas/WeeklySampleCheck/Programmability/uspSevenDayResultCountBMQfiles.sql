CREATE PROCEDURE [WeeklySampleCheck].[uspSevenDayResultCountBMQfiles]
AS
SET NOCOUNT ON

/*
	Purpose:	Report Sample Loaded numbers weekly, FRIDAY
			
	Version			Date			Developer			Comment
	1.0				21/05/2021		Ben King			TASK 450
	1.1				24/07/2021		Chris Ledger		Correct object references
	
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


		TRUNCATE TABLE [WeeklySampleCheck].[SevenDayResultCountBMQfiles]

	WHILE (@CountBack > -7)

			BEGIN 
			;WITH FileNames (Brand, Market, Questionnaire, Files, AuditID, LoadSuccess, FileLoadFailure, FileRowCount)
			AS
				(
				SELECT DISTINCT
					L.Brand, 
					M.Market, 
					L.Questionnaire, 
					F.FileName AS Files,			-- V1.1
					F.AuditID,
					ICF.LoadSuccess,
				    FFR.FileFailureReasonShort AS FileLoadFailure,
					F.FileRowCount
				FROM [WeeklySampleCheck].[LiveBrandMarketQuestionnaire] L
				INNER JOIN [$(SampleDB)].dbo.Markets M ON L.Market = COALESCE(M.DealerTableEquivMarket, M.Market)
				INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SQ
														ON SQ.Market = M.Market
													AND SQ.Brand = L.Brand  
													AND SQ.Questionnaire = L.Questionnaire
				INNER JOIN [$(AuditDB)].dbo.Files F ON SQ.AuditID = F.AuditID
				INNER JOIN [$(AuditDB)].dbo.IncomingFiles ICF ON F.AuditID = ICF.AuditID
				LEFT JOIN [$(AuditDB)].dbo.FileFailureReasons FFR ON ICF.FileLoadFailureID = FFR.FileFailureID	
				WHERE F.ActionDate >= DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack - 1)
				AND F.ActionDate < DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack)
				)
				,
				FileRowLoadedCount (Brand, Market, Questionnaire, AuditID, FileRow_LoadedCount)
			AS
				(
				SELECT DISTINCT
					L.Brand, 
					M.Market, 
					L.Questionnaire,
					SQ.AuditID, 
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
				GROUP BY L.Brand, M.Market, L.Questionnaire, SQ.AuditID
				)
				,
				SelectedCount (Brand, Market, Questionnaire, AuditID, Selected_Count)
			AS
				(
				SELECT DISTINCT
					L.Brand, 
					M.Market, 
					L.Questionnaire,
					SQ.AuditID, 
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
				GROUP BY L.Brand, M.Market, L.Questionnaire, SQ.AuditID
				)

			INSERT INTO [WeeklySampleCheck].[SevenDayResultCountBMQfiles] (Market, Brand, Questionnaire, Frequency, Files, LoadSuccess, FileLoadFailure, FileRowCount, AuditID, FileRow_LoadedCount, Selected_Count, ResultDay)
			SELECT DISTINCT
				L.Market,
				L.Brand,
				L.Questionnaire,
				L.Frequency,
				F.Files,
				F.LoadSuccess,
				F.FileLoadFailure,
				F.FileRowCount,
				FRC.AuditID,
				FRC.FileRow_LoadedCount,
				S.Selected_Count,
				DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack - 1) AS 'ResultDay'
			FROM [WeeklySampleCheck].[LiveBrandMarketQuestionnaire] L
			INNER JOIN [$(SampleDB)].dbo.Markets M ON L.Market = COALESCE(M.DealerTableEquivMarket, M.Market)
			LEFT JOIN FileNames F ON L.Brand = F.Brand
								  AND M.Market = F.Market
								  AND L.Questionnaire = F.Questionnaire	
			LEFT JOIN FileRowLoadedCount FRC ON F.AuditID = FRC.AuditID
											AND	F.Brand = FRC.Brand
											AND M.Market = FRC.Market
											AND F.Questionnaire = FRC.Questionnaire
			LEFT JOIN SelectedCount S ON F.AuditID = S.AuditID
									 AND F.Brand = S.Brand
									 AND M.Market = S.Market
									 AND F.Questionnaire = S.Questionnaire

			SET @CountBack = @CountBack -1

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
