CREATE PROCEDURE Audit.uspAddIncomingFileToAuditUsingSHAChecksum
(
	 @FileName		dbo.FileName
	,@FileType		VARCHAR(50)
	,@FileRowCount	INT
	,@FileChecksum	VARCHAR(100)
	,@LoadSuccess	INT = 0
)
AS

/*
					Purpose:	Add file information for a file load into the Audit database and return the generated AuditID
	
	Release			Version			Date			Developer			Comment
	LIVE				1.0				2022-07-04		Eddie Thomas		Created from uspAddIncomingFileToAudit

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
	
		-- GET THE MAXIMUM AuditID FROM Audit
		DECLARE @AuditID dbo.AuditID
		SELECT @AuditID = ISNULL(MAX(AuditID), 0) + 1 FROM [$(AuditDB)].dbo.Audit

		-- INSERT THE NEW AuditID INTO Audit
		INSERT INTO [$(AuditDB)].dbo.Audit (AuditID)
		SELECT @AuditID

		-- NOW INSERT THE FILE DETAILS
		INSERT INTO [$(AuditDB)].dbo.Files
		(
			 AuditID
			,FileTypeID
			,FileName
			,FileRowCount
			,ActionDate
		)
		SELECT @AuditID, FileTypeID, @FileName, @FileRowCount, GETDATE() FROM [$(AuditDB)].dbo.FileTypes WHERE FileType = @FileType
		
		INSERT INTO [$(AuditDB)].dbo.IncomingFiles
		(
			 AuditID
			,FileChecksum
			,SHA256HashCode
			,LoadSuccess
		)
		--VALUES (@AuditID, @FileChecksum, 0)
		VALUES (@AuditID, -1, @FileChecksum, @LoadSuccess)

	COMMIT TRAN
	
	SELECT @AuditID AS AuditID

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