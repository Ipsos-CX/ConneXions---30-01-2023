CREATE PROCEDURE CRM.uspLost_Leads_AddAuditIDs

@AuditID BIGINT

AS

/*
		Purpose:	Create/Assign AuditIDs to CRM event driven sales records
	
		Version		Developer			Created			Comment
LIVE	1.0			Chris Ledger		2021-08-25		TASK 502: Created
*/

	SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

	BEGIN TRY

		BEGIN TRAN

			UPDATE CRM.Lost_Leads
			SET AuditID = @AuditID
			WHERE AuditID IS NULL

			UPDATE CRM.Lost_Leads_ACCT_MKT_PERM
			SET AuditID = @AuditID
			WHERE AuditID IS NULL

			UPDATE CRM.Lost_Leads_ACCT_MKT_PERM_ITEM
			SET AuditID = @AuditID
			WHERE AuditID IS NULL

			UPDATE CRM.Lost_Leads_CNT_MKT_PERM
			SET AuditID = @AuditID
			WHERE AuditID IS NULL

			UPDATE CRM.Lost_Leads_CNT_MKT_PERM_ITEM
			SET AuditID = @AuditID
			WHERE AuditID IS NULL

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
