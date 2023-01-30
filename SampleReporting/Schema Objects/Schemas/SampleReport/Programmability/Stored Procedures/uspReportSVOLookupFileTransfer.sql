CREATE PROCEDURE [SampleReport].[uspReportSVOLookupFileTransfer]
AS
SET NOCOUNT ON

/*
	Purpose:	Notify Execs of China VIN file load fails
			
	Release			Version			Date			Developer			Comment
	LIVE			1.0				12/04/2021		Ben King			666 - 18375 - SV Data Feed to China
	LIVE			1.1				11/01/2022		Ben King			TASK 738 General Tidy up of solution
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY

	DECLARE @html nvarchar(MAX);

	DECLARE @EmailRecipients nvarchar(250);

	--V1.1
	IF @@ServerName = '1005796-CXNSQLP'
		BEGIN
			SET @EmailRecipients = 'Andrew.Erskine@ipsos.com;Yvonne.Sang@ipsos.com;ben.king@ipsos.com;Chris.ledger@ipsos.com'
		END
	ELSE
		BEGIN
			SET @EmailRecipients = 'ben.king@ipsos.com;Chris.ledger@ipsos.com;Eddie.Thomas@ipsos.com'
		END		

	IF EXISTS (
				SELECT * 
				FROM [$(AuditDB)].dbo.Files F											-- V1.1
				INNER JOIN [$(AuditDB)].dbo.IncomingFiles I ON F.AuditID = I.AuditID
				WHERE F.FileTypeID = 25
				AND CONVERT(DATE, F.ActionDate, 101) = CONVERT(DATE, GETDATE(), 101)
				AND I.LoadSuccess = 0	
			  )

	BEGIN 
			
		
		EXEC [$(ETLDB)].dbo.spQueryToHtmlTable @html = @html OUTPUT,  
		@query = N'SELECT F.*, I.LoadSuccess 
				   FROM Sample_Audit.dbo.files F
				   INNER JOIN Sample_Audit.dbo.IncomingFiles I ON F.AuditID = I.AuditID
				   WHERE F.FileTypeID = 25
				   AND CONVERT(DATE, F.ActionDate, 101) = CONVERT(DATE, GETDATE(), 101)
				   AND I.LoadSuccess = 0', 
		@orderBy = N'ORDER BY 1';
		
		DECLARE @Subject nvarchar(MAX);
		SET @Subject = 'SVO Lookup file(s) failed todays processing - File(s) failed to load';

		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'DBAProfile',
			@recipients = @EmailRecipients, --V1.1
			@subject = @Subject, 
			@body = @html,
			@body_format = 'HTML',
			@from_address = 'CNX_JLR_Output@ipsos-online.com'
	END


	IF EXISTS (
				SELECT * 
				FROM [$(AuditDB)].dbo.Files F											-- V1.1
				INNER JOIN [$(AuditDB)].dbo.IncomingFiles I ON F.AuditID = I.AuditID
				WHERE F.FileTypeID = 25
				AND CONVERT(DATE, F.ActionDate, 101) = CONVERT(DATE, GETDATE(), 101)
				AND I.LoadSuccess = 1	
			  )

	BEGIN 
			
		
		EXEC [$(ETLDB)].dbo.spQueryToHtmlTable @html = @html OUTPUT,  
		@query = N'SELECT F.*, I.LoadSuccess 
				   FROM Sample_Audit.dbo.files F
				   INNER JOIN Sample_Audit.dbo.IncomingFiles I ON F.AuditID = I.AuditID
				   WHERE F.FileTypeID = 25
				   AND CONVERT(DATE, F.ActionDate, 101) = CONVERT(DATE, GETDATE(), 101)
				   AND I.LoadSuccess = 1', 
		@orderBy = N'ORDER BY 1';
		
		
		SET @Subject = 'SVO Lookup file(s) have successfully been processed and uploaded to FTP';

		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'DBAProfile',
			@recipients = @EmailRecipients, --V1.1,
			@subject = @Subject, 
			@body = @html,
			@body_format = 'HTML',
			@from_address = 'CNX_JLR_Output@ipsos-online.com'
	END



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
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH
GO

