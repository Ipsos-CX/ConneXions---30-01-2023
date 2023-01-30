CREATE PROCEDURE [CRM].[uspGeneral_Enquiry_UpdateFileRowCount]

@AuditID BIGINT

AS

/*
		Purpose:	Update the File Row Count in the [$(AuditDB)].dbo.Files table.
	
		Version		Developer			Created			Comment
LIVE	1.0			Chris Ledger		2021-03-24		Created
LIVE	1.1			Chris Ledger		2021-09-22		TASK 502 - Reformat
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

			-- Get the number of rows loaded
			DECLARE @FileRowCount  int
			
			SELECT @FileRowCount = COUNT(*) 
			FROM CRM.General_Enquiry GE
			WHERE GE.AuditID = @AuditID
			
			-- Write to the Files audit table 
			UPDATE [$(AuditDB)].dbo.Files
			SET FileRowCount = @FileRowCount
			WHERE AuditID = @AuditID			

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
