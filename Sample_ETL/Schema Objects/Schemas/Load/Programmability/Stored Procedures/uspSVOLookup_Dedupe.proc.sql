CREATE PROCEDURE [Load].[uspSVOLookup_Dedupe]

AS

/*
	Purpose: Dedupe SVO Lookup table
	
	Version		Date			Developer			Comment
	1.1			2021-07-15		Chris Ledger		Task 552: Update SaleType
*/

SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	UPDATE LK
	SET LK.ParentAuditItemID = M.ParentAuditItemID
	FROM Stage.SVOLookup LK
		INNER JOIN (	SELECT MAX(AuditItemID) AS ParentAuditItemID,
							Vin
						FROM Stage.SVOLookup
						GROUP BY Vin) M ON	M.Vin = LK.Vin
			
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
