CREATE PROCEDURE [LostLeads].[uspAddNewBDCs]
/* Purpose:	Insert new records into BDC lookup table

	Version		Date			Developer			Comment
	1.0			2018-02-22		Chris Ledger		BUG 14555: Created
	1.1			2019-11-08		Chris Ledger		BUG 14555: Add Canada

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
	

		-- ADD THE NEW ITEMS TO THE LOOKUP 
		INSERT INTO LostLeads.BDC (BDCName)
		SELECT L.LostSalesProvider AS BDCName
		FROM Lookup.LostLeadsAgencyStatus L
		WHERE L.Market IN ('US','CA')
		AND L.LostSalesProvider IS NOT NULL
		AND NOT EXISTS	(SELECT *
						FROM LostLeads.BDC B
						WHERE B.BDCName = L.LostSalesProvider)
		GROUP BY L.LostSalesProvider
		

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
