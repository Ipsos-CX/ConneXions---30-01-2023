CREATE PROCEDURE SampleReceipt.uspGetMarketsAndRegionsToOutput

AS

SET NOCOUNT ON;

DECLARE @ErrorNumber INT;
DECLARE @ErrorSeverity INT;
DECLARE @ErrorState INT;
DECLARE @ErrorLocation NVARCHAR(500);
DECLARE @ErrorLine INT;
DECLARE @ErrorMessage NVARCHAR(2048);

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

BEGIN TRY



/*
	Purpose:	Builds tables for the Sample Receipt Report package to output.
		
	Version		Date				Developer			Comment
	1.0			10/07/2017			Chris Ross			Created
	1.1			11/12/2017			Ben King			BUG 14386 - Belux Market Equivalent does not match Market
																	in SampleReceipt.ReportOutputs
	1.2			15/01/2020			Chris Ledger 		BUG 15372 - Correct incorrect cases
*/


		------------------------------------------------------------------
		-- Get the saved FromDate
		------------------------------------------------------------------

		DECLARE @FromDate DATETIME2
		SELECT @FromDate = LastRunDate FROM SampleReceipt.SystemValues




		------------------------------------------------------------------------------------
		-- Return the enabled Market/Region combo's which have files received since FromDate
		------------------------------------------------------------------------------------

			
		SELECT DISTINCT ro.MarketOrRegionFlag, ro.MarketRegion, ro.Questionnaire, ro.USDateFormat, ro.TLVal2_DaysSinceSampleRec, ro.TLVal3_DaysSinceSampleRec
		FROM [$(AuditDB)].dbo.Files f
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging sq ON sq.AuditID = f.AuditID
		INNER JOIN [$(SampleDB)].dbo.Markets m ON m.Market = sq.Market
		INNER JOIN [$(SampleDB)].dbo.Regions r ON r.RegionID = m.RegionID
		INNER  JOIN SampleReceipt.ReportOutputs  ro ON ((ro.MarketOrRegionFlag = 'M' AND 	
																ro.MarketRegion = (CASE ro.MarketRegion --V1.1
																								 WHEN 'Belgium' THEN m.Market
																								 WHEN 'Luxembourg' THEN m.Market
																								 ELSE COALESCE(m.DealerTableEquivMarket, m.Market)
																								 END))	
														OR	(ro.MarketOrRegionFlag = 'R' AND ro.MarketRegion = r.Region)
													  )
												   AND ro.Questionnaire = sq.Questionnaire
												   AND ro.Enabled = 1
		WHERE f.ActionDate >= @FromDate
		AND f.FileTypeID = 1
				


END TRY

BEGIN CATCH

    SELECT  @ErrorNumber = ERROR_NUMBER() ,
            @ErrorSeverity = ERROR_SEVERITY() ,
            @ErrorState = ERROR_STATE() ,
            @ErrorLocation = ERROR_PROCEDURE() ,
            @ErrorLine = ERROR_LINE() ,
            @ErrorMessage = ERROR_MESSAGE();

    EXEC [$(ErrorDB)].[dbo].uspLogDatabaseError @ErrorNumber,
        @ErrorSeverity, @ErrorState, @ErrorLocation, @ErrorLine,
        @ErrorMessage;
	
    RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine);
	
END CATCH;
