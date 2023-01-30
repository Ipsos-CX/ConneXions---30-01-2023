CREATE PROCEDURE SelectionOutput.uspAuditTurkeyOutput
(
	@FileName VARCHAR(255),
	@OutputFileProduced INT = 0 OUTPUT
)
AS

/*
		Purpose:	Audit Turkey output
	
		Version			Date			Developer			Comment
LIVE	1.0				2021-10-14		Chris Ledger		Created
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
	
		DECLARE @AuditID INT
		DECLARE @RowCount INT
		DECLARE @Date DATETIME
		SET @Date = GETDATE()
		
					
		-- GET THE ROWCOUNT
		SET @RowCount = (SELECT COUNT(*) FROM SelectionOutput.vwTurkeyResponses)

		-- AUDIT OUTPUT
		IF @RowCount > 0
		BEGIN

			-- SET OUTPUTFILE
			SET @OutputFileProduced = 1	

			-- CHECK TO SEE IF FILE ALREADY EXISTS
			SELECT @AuditID = ISNULL((SELECT TOP 1 AuditID FROM [$(AuditDB)].dbo.Files WHERE FileName = @FileName),0)

	
			-- EXISTING FILE
			IF @AuditID > 0
			BEGIN
				UPDATE [$(AuditDB)].dbo.Files SET FileRowCount = FileRowCount + @RowCount WHERE AuditID = @AuditID
			END;
	
	
			-- NEW FILE
			IF @AuditID = 0
			BEGIN
	
				-- GET AN AUDITID
				SELECT @AuditID = ISNULL(MAX(AuditID), 0) + 1 FROM [$(AuditDB)].dbo.Audit
		
				INSERT INTO [$(AuditDB)].dbo.Audit
				SELECT @AuditID

				INSERT INTO [$(AuditDB)].dbo.Files
				(
					AuditID,
					FileTypeID,
					FileName,
					FileRowCount,
					ActionDate
				)
				VALUES
				(
					@AuditID, 
					(SELECT FileTypeID FROM [$(AuditDB)].dbo.FileTypes WHERE FileType = 'Selection Output'),
					@FileName,
					@RowCount,
					@Date
				)

				INSERT INTO [$(AuditDB)].dbo.OutgoingFiles (AuditID, OutputSuccess)
				VALUES (@AuditID, 1)
	
			END;

		
			-- WRITE BACK THE AUDITID
			UPDATE TR
			SET TR.OutputAuditID = @AuditID
			FROM SelectionOutput.TurkeyResponses TR
			WHERE TR.OutputAuditID IS NULL
				AND TR.ValidatedData = 1

		END;
		
	COMMIT TRAN
		
END TRY
BEGIN CATCH

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
		
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH
