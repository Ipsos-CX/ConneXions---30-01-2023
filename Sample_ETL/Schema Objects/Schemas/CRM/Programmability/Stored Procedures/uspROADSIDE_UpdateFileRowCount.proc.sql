CREATE PROCEDURE [CRM].[uspROADSIDE_UpdateFileRowCount]

@AuditID BIGINT

AS

/*
		Purpose:	Update the File Row Count in the Sample_Audit.dbo.Files table.
	
		Version		Developer			Created			Comment
LIVE	1.0			Chris Ross			09/12/2015		Created
LIVE	1.1			Chris Ledger		22/09/2021		TASK 502 - Reformat
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
			FROM CRM.RoadsideIncident_Roadside RDS
			WHERE RDS.AuditID = @AuditID
			
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
