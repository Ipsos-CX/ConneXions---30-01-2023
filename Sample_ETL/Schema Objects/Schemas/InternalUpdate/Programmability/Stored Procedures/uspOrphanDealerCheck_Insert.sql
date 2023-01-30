CREATE PROCEDURE [InternalUpdate].[uspOrphanDealerCheck_Insert]

AS

/*
	Purpose:	Load Dealer Oprhan ID and check what appears coded. Re-export coded dealers
	
	Version			Date			Developer			Comment
	1.0				26/02/2020		Ben King			BUG 16676
	1.1				27/08/2021		Chris Ledger		Fix database references (N.B. SP should be in SampleReporting database)

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
	
		--INSERT LATEST DOWNLOAD AUDIT HISTORY
		INSERT INTO [$(SampleReporting)].SampleReport.OrphanDealerIDCheck 
		(
			ImportedAuditItemID, IsOrphan, AuditID, AuditItemID
		)
		SELECT ImportedAuditItemID, IsOrphan, AuditID, AuditItemID
		FROM   Stage.OrphanIDCheck


		TRUNCATE TABLE [$(SampleReporting)].SampleReport.OrphanDealerIDCheck_Latest

		--INSERT LATEST ID'S TO CHECK AGAINST CURRENT LIVE DATA
		INSERT INTO [$(SampleReporting)].SampleReport.OrphanDealerIDCheck_Latest
		(
			ImportedAuditItemID, IsOrphan, AuditID, AuditItemID, RunDate
		)
		SELECT ImportedAuditItemID, IsOrphan, AuditID, AuditItemID, GetDate()
		FROM   Stage.OrphanIDCheck
		WHERE  IsOrphan = 1


		--SET CODED DEALERS TO RE-EXPORT IF FLAGGED AS ORPHAN IN LASTEST CHECK FILE RECEVED
		UPDATE Y
			SET Y.CheckSumCalc = 0, Y.ReExported = 1
			FROM [$(SampleReporting)].SampleReport.YearlyEchoHistory Y
		INNER JOIN [$(SampleReporting)].SampleReport.OrphanDealerIDCheck_Latest BG ON Y.AuditItemID = BG.ImportedAuditItemID
		WHERE Y.UncodedDealer = 0
	
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

	EXEC [Sample_Errors].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH