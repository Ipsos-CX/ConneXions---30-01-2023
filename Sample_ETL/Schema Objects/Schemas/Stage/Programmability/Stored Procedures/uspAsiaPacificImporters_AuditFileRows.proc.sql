CREATE PROCEDURE Stage.uspAsiaPacificImporters_AuditFileRows

AS

/*
		Purpose:	Generate AuditItems and write them to Audit and the AsiaPacificImporters staging table
	
		Version		Date				Developer			Comment
LIVE	1.0			2021-10-11			Chris Ledger		Created

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

		UPDATE Stage.AsiaPacificImporters
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
		FROM Stage.AsiaPacificImporters


		-- INSERT A FILE ROW FOR EACH AUDITITEM
		INSERT INTO [$(AuditDB)].dbo.FileRows
		(
			AuditItemID,
			PhysicalRow
		)
		SELECT
			AuditItemID,
			ID
		FROM Stage.AsiaPacificImporters


		-- UPDATE FILEROWCOUNT BECAUSE LF'S WITHIN FIELDS PRODUCING INCORRECT RESULTS 
		;WITH CTE_FileRowCount AS
		(
			SELECT API.AuditID,
				COUNT(*) AS FileRowCount
			FROM Stage.AsiaPacificImporters API
			GROUP BY API.AuditID
		)
		UPDATE F SET F.FileRowCount = FRC.FileRowCount
		FROM [$(AuditDB)].dbo.Files F
			INNER JOIN CTE_FileRowCount FRC ON F.AuditID = FRC.AuditID
	
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