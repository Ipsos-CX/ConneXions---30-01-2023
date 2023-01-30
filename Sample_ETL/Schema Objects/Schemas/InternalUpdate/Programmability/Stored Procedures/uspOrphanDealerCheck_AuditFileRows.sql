CREATE PROCEDURE [InternalUpdate].[uspOrphanDealerCheck_AuditFileRows]

AS

/*
	Purpose:	Generate AuditItems and write them to Audit and the Orphan ID check table
	
	Version			Date			Developer			Comment
	1.0				26/02/2020		Ben King			BUG 16676
	1.1				01/04/2020		Chris Ledger		BUG 15372 - Tidy database reference

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

		-- GENERATE THE AuditItems
		DECLARE @MaxAuditItemID dbo.AuditItemID
		
		SELECT @MaxAuditItemID = MAX(AuditItemID) FROM [$(AuditDB)].dbo.AuditItems

		UPDATE Stage.OrphanIDCheck
		SET AuditItemID = ID + @MaxAuditItemID

		-- INSERT NEW AUDITITEMS INTO AuditItems
		INSERT INTO [$(AuditDB)].dbo.AuditItems
		(
			AuditID,
			AuditItemID
		)
		SELECT
			AuditID,
			AuditItemID
		FROM Stage.OrphanIDCheck

		-- INSERT A FILE ROW FOR EACH AUDITITEM
		INSERT INTO [$(AuditDB)].dbo.FileRows
		(
			AuditItemID,
			PhysicalRow
		)
		SELECT
			AuditItemID,
			ID
		FROM Stage.OrphanIDCheck


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
