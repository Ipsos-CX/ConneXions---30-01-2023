CREATE PROCEDURE [CRM].[uspLandRover_Experience_AddAuditIDs]

@AuditID BIGINT

AS

/*
		Purpose:	Create/Assign AuditIDs to CRM event driven LR EXPEREINCE
	
		Version		Developer			Created			Comment
LIVE		1.0			Ben King			2022-05-26		TASK 879: Created
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

			UPDATE CRM.LandRover_Experience
			SET AuditID = @AuditID
			WHERE AuditID IS NULL

			UPDATE CRM.LandRover_Experience_ACCT_MKT_PERM
			SET AuditID = @AuditID
			WHERE AuditID IS NULL

			UPDATE CRM.LandRover_Experience_ACCT_MKT_PERM_ITEM
			SET AuditID = @AuditID
			WHERE AuditID IS NULL

			UPDATE CRM.LandRover_Experience_CNT_MKT_PERM
			SET AuditID = @AuditID
			WHERE AuditID IS NULL

			UPDATE CRM.LandRover_Experience_CNT_MKT_PERM_ITEM
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
GO