CREATE PROCEDURE CustomerUpdateFeeds.uspGetNonSolicitationReports
	@Brand varchar(50)
AS

/*

***************************************************************************
**
**  Description: Generates the Non-Solicitation Reports.   
**
**
**	Date		Author			Ver		Desctiption
**	----		------			----	-----------
**	2019-02-08	Chris Ledger	1.1		Bug 15221 - Separate out Denmark, Sweden and Norway weekly customer updates
**									
***************************************************************************

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
		NS.Market, 
		ISNULL(NS.DealerCode,'') AS DealerCode
	FROM CustomerUpdateFeeds.ReportingTable_Nonsolicitations NS
	LEFT JOIN CustomerUpdateFeeds.EmailMarkets EM ON NS.Market = EM.MarketDealerTableTxt
												AND NS.DealerCode = EM.DealerCode			
												AND EM.Active = 1					
	WHERE NS.Manufacturer = @Brand



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
