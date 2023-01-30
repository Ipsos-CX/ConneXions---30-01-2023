CREATE PROCEDURE [SampleReport].[uspReportChinaVINfileFailure]
AS
SET NOCOUNT ON

/*
	Purpose:	Notify Execs of China VIN file load fails
			
	Release			Version			Date			Developer			Comment
	LIVE			1.0				12/04/2021		Ben King			Creation BUG 18109
	LIVE			1.1				24/08/2021		Chris Ledger		Correct object references
	LIVE			1.2				11/01/2022		Ben King			TASK 738 General Tidy up of solution
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY

	--V1.2
	DECLARE @EmailRecipients nvarchar(250);

	IF @@ServerName = '1005796-CXNSQLP'
		BEGIN
			SET @EmailRecipients = 'Andrew.Erskine@ipsos.com;ben.king@ipsos.com; Eddie.Thomas@ipsos.com; Chris.Ledger@ipsos.com;Dipak.Gohil@ipsos.com'
		END
	ELSE
		BEGIN
			SET @EmailRecipients = 'ben.king@ipsos.com'
		END	

	IF EXISTS (
				SELECT * 
				FROM [$(AuditDB)].dbo.Files F											-- V1.1
				INNER JOIN [$(AuditDB)].dbo.IncomingFiles I ON F.AuditID = I.AuditID
				WHERE F.FileTypeID = 23
				AND CONVERT(DATE, F.ActionDate, 101) = CONVERT(DATE, GETDATE(), 101)
				AND I.LoadSuccess = 0	
			  )

	BEGIN 
			
		DECLARE @html nvarchar(MAX);
		EXEC [$(ETLDB)].dbo.spQueryToHtmlTable @html = @html OUTPUT,  
		@query = N'SELECT F.*, I.LoadSuccess 
				   FROM Sample_Audit.dbo.files F
				   INNER JOIN Sample_Audit.dbo.IncomingFiles I ON F.AuditID = I.AuditID
				   WHERE F.FileTypeID = 23
				   AND CONVERT(DATE, F.ActionDate, 101) = CONVERT(DATE, GETDATE(), 101)
				   AND I.LoadSuccess = 0', 
		@orderBy = N'ORDER BY 1';
		
		DECLARE @Subject nvarchar(MAX);
		SET @Subject = 'China VIN decoding - Files failed to load';

		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'DBAProfile',
			@recipients = @EmailRecipients, --V1.2
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
