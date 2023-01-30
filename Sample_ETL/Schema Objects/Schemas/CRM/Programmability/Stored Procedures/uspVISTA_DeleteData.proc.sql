CREATE PROCEDURE CRM.uspVISTA_DeleteData

@AuditID BIGINT

AS

/*
		Purpose:	Delete data from CRM event driven sales records
	
		Version		Developer			Created			Comment
LIVE	1.0			Chris Ledger		2021-09-22		TASK 502 - Created
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

			DELETE
			FROM CRM.Vista_Contract_Sales
			WHERE AuditID IS NULL
				OR AuditID = @AuditID

			DELETE
			FROM CRM.VISTA_ACCT_MKT_PERM
			WHERE AuditID IS NULL
				OR AuditID = @AuditID

			DELETE
			FROM CRM.VISTA_ACCT_MKT_PERM_ITEM
			WHERE AuditID IS NULL
				OR AuditID = @AuditID

			DELETE
			FROM CRM.VISTA_CNT_MKT_PERM
			WHERE AuditID IS NULL
				OR AuditID = @AuditID

			DELETE
			FROM CRM.VISTA_CNT_MKT_PERM_ITEM
			WHERE AuditID IS NULL
				OR AuditID = @AuditID

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
