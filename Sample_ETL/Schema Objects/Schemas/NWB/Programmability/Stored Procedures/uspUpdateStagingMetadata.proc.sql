CREATE PROCEDURE NWB.uspUpdateStagingMetadata
	@AuditID bigint
AS

/*
	Purpose:	Generate AuditItems and any other metadata and write to the appropriate records in 
				the NWB staging for the AuditID supplied.
	
	Version			Date			Developer			Comment
	1.0				17-07-2019		Chris Ross			BUG 15430.  Original version.

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

		
		-- SET the AuditItemIDs
		UPDATE nwb
		SET nwb.AuditItemID = nwb.PhysicalRowID + @MaxAuditItemID
		FROM NWB.SelectionOutputsStaging nwb
		WHERE nwb.AuditID = @AuditID
		
		-- INSERT NEW AUDITITEMS INTO AuditItems
		INSERT INTO [$(AuditDB)].dbo.AuditItems
		(
			AuditID,
			AuditItemID
		)
		SELECT
			AuditID,
			AuditItemID
		FROM NWB.SelectionOutputsStaging
		WHERE AuditID = @AuditID
		
		-- INSERT A FILE ROW FOR EACH AUDITITEM
		INSERT INTO [$(AuditDB)].dbo.FileRows
		(
			AuditItemID,
			PhysicalRow
		)
		SELECT
			AuditItemID,
			PhysicalRowID
		FROM NWB.SelectionOutputsStaging
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