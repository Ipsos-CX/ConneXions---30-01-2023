CREATE PROCEDURE [SampleReport].[uspGetDailySampleVolumeRegion]

AS

SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

	/*
		Purpose: Returns Regions to loop through per report and email details.
			
		Releae		Version		Date				Developer			Comment
		LIVE		1.0			26/08/2015			Ben King			TASK 931 - Sample Volume Report
	*/
	
	BEGIN TRY
	

	SELECT DISTINCT
		DE.RegionReportGroup,
		ISNULL(DE.ToDistribution,'') AS ToDistribution,
		ISNULL(DE.CcDistribution,'') AS CcDistribution
	FROM SampleReport.SampleVolumeEmailDistribution DE
	LEFT JOIN [$(SampleDB)].dbo.Regions R ON DE.RegionReportGroup = R.Region
	LEFT JOIN [$(SampleDB)].dbo.Markets M ON R.RegionID = M.RegionID
	LEFT JOIN [WeeklySampleCheck].[LiveBrandMarketQuestionnaire] L ON L.Market = COALESCE(M.DealerTableEquivMarket, M.Market)
	WHERE L.VolumeReportOutput =1
	OR DE.RegionReportGroup = 'ALL'
	

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



