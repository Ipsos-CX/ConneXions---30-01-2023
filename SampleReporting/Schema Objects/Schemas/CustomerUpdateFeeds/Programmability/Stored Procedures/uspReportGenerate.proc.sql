CREATE PROCEDURE [CustomerUpdateFeeds].[uspReportGenerate]

AS

/*

	Purpose:		Generates the base table for the Customer Update report
		
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


	TRUNCATE TABLE CustomerUpdateFeeds.ReportingTable_Updates

	INSERT INTO CustomerUpdateFeeds.ReportingTable_Updates (Market, Manufacturer, DealerCode, PAGCode)
	SELECT DISTINCT F.Market, F.Manufacturer, 'ALL' AS DealerCode, ISNULL(PAGCode,'') AS PAGCode
	FROM CustomerUpdateFeeds.CustomerUpdateFeed F
	WHERE F.Market IS NOT NULL 
	AND F.Manufacturer IS NOT NULL
	AND ((F.ActionDate BETWEEN CONVERT(DATE, GETDATE() -8) AND CONVERT(DATE, GETDATE()))
		 OR (F.BouncebackActionDate BETWEEN CONVERT(DATE, GETDATE() -8) AND CONVERT(DATE, GETDATE()))
		)
	UNION
	SELECT DISTINCT F.Market, F.Manufacturer, F.DealerCode, ISNULL(F.PAGCode,'') AS PAGCode
	FROM CustomerUpdateFeeds.CustomerUpdateFeed F
	WHERE F.Market IS NOT NULL 
	AND F.Manufacturer IS NOT NULL
	AND ((F.ActionDate BETWEEN CONVERT(DATE, GETDATE() -7) AND CONVERT(DATE, GETDATE()))
		 OR (F.BouncebackActionDate BETWEEN CONVERT(DATE, GETDATE() -7) AND CONVERT(DATE, GETDATE()))
		)


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
