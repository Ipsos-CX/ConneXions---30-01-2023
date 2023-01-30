CREATE PROCEDURE [SampleReport].[uspGetDailySampleVolumeOutputByFile]
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
	
	TRUNCATE TABLE [SampleReport].[GetDailySampleVolumeBMQbyFile]

	INSERT INTO [SampleReport].[GetDailySampleVolumeBMQbyFile] (Market, Brand, Questionnaire, Frequency, Files, LoadSuccess, FileLoadFailure, FileRowCount, AuditID, FileRow_LoadedCount, Selected_Count, ResultDate, ReportDate, EventsTooYoung_Count, Region)
	SELECT	DISTINCT 
			COALESCE(M.DealerTableEquivMarket, M.Market) AS Market,
			SV.Brand,
			SV.Questionnaire,
			SV.Frequency,
			SV.Files,
			SV.LoadSuccess,
			SV.FileLoadFailure,
			SV.FileRowCount,
			SV.AuditID,
			SV.FileRow_LoadedCount,
			SV.Selected_Count,
			SV.ResultDate,
			SV.ReportDate,
			SV.EventsTooYoung_Count,
			R.Region
	FROM [SampleReport].[DailySampleVolumeBMQbyFile] SV
	LEFT JOIN [$(SampleDB)].dbo.Markets M ON SV.Market = COALESCE(M.DealerTableEquivMarket, M.Market)
	LEFT JOIN [$(SampleDB)].dbo.Regions R ON M.RegionID = R.RegionID 
	WHERE (@Region = 'ALL' AND R.Region IN (SELECT Region FROM [$(SampleDB)].dbo.Regions) AND SV.Files IS NOT NULL AND CONVERT(DATE, SV.Reportdate) = CONVERT(DATE, GETDATE()))
	OR (@Region <> 'ALL' AND R.Region = @Region AND SV.Files IS NOT NULL AND CONVERT(DATE, SV.Reportdate) = CONVERT(DATE, GETDATE()))
	
	ORDER BY Market,SV.Questionnaire,SV.Brand
	
		
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