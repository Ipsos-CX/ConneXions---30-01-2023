CREATE PROCEDURE [SampleReport].[uspDailySampleVolumeCountBMQbyFile]
@Weekly BIT = 0,
@Daily BIT = 0
AS
SET NOCOUNT ON

/*
	Purpose:	Report Sample Files Loaded - current week
			
	Release		Version			Date			Developer			Comment
	LIVE		1.0				28/07/2022		Ben King			TASK 931 - Sample Volume Report

*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY


		DECLARE @LoopCount INT
		DECLARE @StartDate DATETIME

		IF @Daily = 1 AND DATENAME(DW,GETDATE()) <> 'Sunday'
			BEGIN
				SET @LoopCount = -7
				SET @StartDate = DATEADD(DAY,  9-DATEPART(WEEKDAY, GETDATE()), GETDATE())
			END 

		ELSE IF @Daily = 1 AND DATENAME(DW,GETDATE()) = 'Sunday'
			BEGIN
				SET @LoopCount = -7
				SET @StartDate = DATEADD(DAY,1,GETDATE())
			END

		ELSE IF @Weekly = 1
			BEGIN
				SET @LoopCount = -35 --5 WEEKS
				SET @StartDate = DATEADD(DAY,1,GETDATE())
			END
	 

		DECLARE @CountBack INT
		SET @CountBack = 0


		TRUNCATE TABLE [SampleReport].[DailySampleVolumeBMQbyFile]


	WHILE (@CountBack > @LoopCount)

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
				WHERE SQ.LoadedDate >= DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack - 1)
				AND SQ.LoadedDate < DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack)
				AND L.VolumeReportOutput = 1
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
				WHERE SQ.LoadedDate >= DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack - 1)
				AND SQ.LoadedDate < DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack)
				AND L.VolumeReportOutput = 1
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
				WHERE SQ.LoadedDate >= DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack - 1)
				AND SQ.LoadedDate < DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack)
				AND SQ.CaseID IS NOT NULL
				AND L.VolumeReportOutput = 1
				GROUP BY L.Brand, M.Market, L.Questionnaire, SQ.AuditID
				),

				EventsTooYoungCount (Brand, Market, Questionnaire, AuditID, EventsTooYoung_Count)
			AS
				(
				SELECT DISTINCT
					L.Brand, 
					M.Market, 
					L.Questionnaire,
					SQ.AuditID, 
					COUNT(SQ.EventDateTooYoung) AS 'EventsTooYoung_Count'
				FROM [WeeklySampleCheck].[LiveBrandMarketQuestionnaire] L
				INNER JOIN [$(SampleDB)].dbo.Markets M ON L.Market = COALESCE(M.DealerTableEquivMarket, M.Market)
				INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SQ
													 ON SQ.Market = M.Market
													AND SQ.Brand = L.Brand  
													AND SQ.Questionnaire = L.Questionnaire
				INNER JOIN [$(AuditDB)].dbo.Files F ON SQ.AuditID = F.AuditID
				WHERE SQ.LoadedDate >= DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack - 1)
				AND SQ.LoadedDate < DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack)
				AND SQ.EventDateTooYoung = 1
				AND L.VolumeReportOutput = 1
				GROUP BY L.Brand, M.Market, L.Questionnaire, SQ.AuditID
				)

			INSERT INTO [SampleReport].[DailySampleVolumeBMQbyFile] (Market, Brand, Questionnaire, Frequency, Files, LoadSuccess, FileLoadFailure, FileRowCount, AuditID, FileRow_LoadedCount, Selected_Count, ResultDate, ReportDate, EventsTooYoung_Count)
			SELECT DISTINCT
				L.Market,
				L.Brand,
				L.Questionnaire,
				L.Frequency,
				F.Files,
				ISNULL(F.LoadSuccess,''),
				ISNULL(F.FileLoadFailure,''),
				ISNULL(F.FileRowCount,''),
				FRC.AuditID,
				ISNULL(FRC.FileRow_LoadedCount,''),
				ISNULL(S.Selected_Count,''),
				DATEADD(dd, DATEDIFF(dd, 0, @StartDate), @CountBack - 1) AS 'ResultDate',
				CONVERT(date, GETDATE()) AS 'ReportDate',
				ISNULL(E.EventsTooYoung_Count,'')
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
			LEFT JOIN EventsTooYoungCount E ON F.AuditID = E.AuditID
									 AND F.Brand = E.Brand
									 AND M.Market = E.Market
									 AND F.Questionnaire = E.Questionnaire
			WHERE L.VolumeReportOutput = 1
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

