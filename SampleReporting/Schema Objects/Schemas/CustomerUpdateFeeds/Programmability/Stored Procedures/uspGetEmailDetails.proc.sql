CREATE PROCEDURE [CustomerUpdateFeeds].[uspGetEmailDetails]

AS

/*

	Purpose:		Get email details 
		
	Version			Date			Developer			Comment
	1.1				08-02-2019		Chris Ledger		BUG 15221 - Move code from package to SP.
	1.2				26-09-2019		Chris Ledger		BUG 15562 - Add PAGCode
	1.3				27-09-2019		Chris Ledger		BUG 15562 - Add DealerName

*/


SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


	SELECT DISTINCT 
		RU.Market,
		RU.DealerCode,
		ISNULL(EM.PAGCode,'') AS PAGCode,
		ISNULL(EM.DealerName,'') AS DealerName,
		EM.EmailRecipients, 
		EM.EmailCC,
		EM.EmailNonProd
	FROM CustomerUpdateFeeds.ReportingTable_Updates RU
	INNER JOIN CustomerUpdateFeeds.EmailMarkets EM ON RU.Market = EM.MarketDealerTableTxt
												AND RU.DealerCode = EM.DealerCode
												AND EM.Active = 1
	LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON RU.DealerCode = D.OutletCode
											AND RU.Market = D.Market
	WHERE EM.PAGCode IS NULL

	UNION

	SELECT DISTINCT 
		RU.Market,
		RU.PAGCode AS DealerCode,
		ISNULL(RU.PAGCode,'') AS PAGCode,
		ISNULL(EM.DealerName,'') AS DealerName,
		EM.EmailRecipients, 
		EM.EmailCC,
		EM.EmailNonProd
	FROM CustomerUpdateFeeds.ReportingTable_Updates RU
	INNER JOIN CustomerUpdateFeeds.EmailMarkets EM ON RU.Market = EM.MarketDealerTableTxt
												AND RU.PAGCode = EM.PAGCode
												AND EM.Active = 1
	LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON RU.PAGCode = D.PAGCode
											AND RU.Market = D.Market
	WHERE EM.PAGCode IS NOT NULL


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