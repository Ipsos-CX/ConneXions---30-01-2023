CREATE PROCEDURE [Audit].[uspAddIncomingFileToAudit]
(
	 @FileName dbo.FileName
	,@FileType VARCHAR(50)
	,@FileRowCount INT
	,@FileChecksum INT
	,@LoadSuccess INT = 0
)
AS

/*
	Purpose:	Add file information for a file load into the Audit database and return the generated AuditID
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from trigger on [Prophet-ETL].dbo.vwAUDIT_SampleFiles
	1.1				09-10-2015		Chris Ross			Assumed Peter Doyle change which had not been released.  Was causing the 
														AFRL Code lookup file load to fail.

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
			,LoadSuccess
		)
		--VALUES (@AuditID, @FileChecksum, 0)
		VALUES (@AuditID, @FileChecksum, @LoadSuccess)

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