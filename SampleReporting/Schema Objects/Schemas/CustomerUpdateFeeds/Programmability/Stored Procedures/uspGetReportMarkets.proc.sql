CREATE PROCEDURE [CustomerUpdateFeeds].[uspGetReportMarkets]
	@Manufacturer varchar(200)
AS

/*

	Purpose:		Get reports 
		
	Version			Date			Developer			Comment
	1.1				08-02-2019		Chris Ledger		BUG 15221 - Move code from package to SP.
	1.2				26-09-2019		Chris Ledger		BUG 15562 - Add PAGCode

*/


SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


	SELECT DISTINCT RU.Market, 
		ISNULL(RU.DealerCode,'') AS DealerCode,
		'' AS PAGCode
	FROM CustomerUpdateFeeds.ReportingTable_Updates RU
	INNER JOIN CustomerUpdateFeeds.EmailMarkets EM ON RU.Market = EM.MarketDealerTableTxt
												AND RU.DealerCode = EM.DealerCode								
												AND EM.Active = 1
	WHERE RU.Manufacturer = @Manufacturer

	UNION

	SELECT DISTINCT RU.Market, 
		ISNULL(RU.PAGCode,'') AS DealerCode,
		ISNULL(RU.PAGCode,'') AS PAGCode
	FROM CustomerUpdateFeeds.ReportingTable_Updates RU
	INNER JOIN CustomerUpdateFeeds.EmailMarkets EM ON RU.Market = EM.MarketDealerTableTxt
												AND RU.PAGCode = EM.PAGCode								
												AND EM.Active = 1
	WHERE RU.Manufacturer = @Manufacturer


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