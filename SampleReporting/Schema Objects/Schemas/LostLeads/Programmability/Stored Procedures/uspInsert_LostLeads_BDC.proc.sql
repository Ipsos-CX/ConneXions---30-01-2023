CREATE PROCEDURE [LostLeads].[uspInsert_LostLeads_BDC]
/* Purpose:	Copy BDC Information to EventX_LostLeads_BDC table

	Version		Date			Developer			Comment
	1.0			2018-02-22		Chris Ledger		BUG 14555: Created
	1.1			2018-03-07		Chris Ledger		BUG 14555: Change location of table
	1.2			2019-11-08		Chris Ledger        BUG 14555: Add Market
	1.3			2020-01-16		Chris Ledger		BUG 15372 - Move to SampleReporting from Sample_ETL database
*/
AS
SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


	BEGIN TRAN
	
		-- COPY DATA TO EventX_LostLeads_BDC TABLE
		INSERT INTO dbo.EventX_LostLeads_BDC (Market, RetailerCode, Retailer, Brand, BDCName, BDCCode, Confirmation)
		SELECT 
		L.Market,
		L.CICode AS RetailerCode,
		L.Retailer,
		L.Brand,
		B.BDCName,
		B.BDCCode,
		L.Confirmation
		FROM [$(ETLDB)].Lookup.LostLeadsAgencyStatus L
		LEFT JOIN [$(ETLDB)].LostLeads.BDC B ON L.LostSalesProvider = B.BDCName
		WHERE L.Market IN ('US','CA')
		ORDER BY B.BDCCode		

	COMMIT TRAN

END TRY
BEGIN CATCH

	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END

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
