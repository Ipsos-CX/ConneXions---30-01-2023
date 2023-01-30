CREATE PROCEDURE [SampleReport].[uspReportsMissingFIMSdownload]
AS
SET NOCOUNT ON

/*
	Purpose:	Email Alert - FIMs file not downloaded
			
	Release				Version			Date			Developer			Comment
	LIVE				1.1				15/12/2021      Ben King			Task 732 - Send email alert if there is no FIMs file
	LIVE				1.1				11/01/2022		Ben King			TASK 738 General Tidy up of solution
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY

	DECLARE @html nvarchar(MAX);

	DECLARE @EmailRecipients nvarchar(250); -- v1.1

	IF NOT EXISTS 
			(
				SELECT * 
				FROM [$(AuditDB)].dbo.Files F											
				INNER JOIN [$(AuditDB)].dbo.IncomingFiles I ON F.AuditID = I.AuditID
				WHERE F.FileName LIKE 'IPSOS_Franchise_Report_%'
				AND CONVERT(DATE, F.ActionDate, 101) = CONVERT(DATE, GETDATE(), 101)
				AND I.LoadSuccess = 1				
			)

	AND EXISTS
		    (
				SELECT * 
				FROM [$(AuditDB)].dbo.Files F											
				INNER JOIN [$(AuditDB)].dbo.IncomingFiles I ON F.AuditID = I.AuditID
				WHERE F.FileName LIKE 'IPSOS_Franchise_Report_%'
				AND CONVERT(DATE, F.ActionDate, 101) = CONVERT(DATE, GETDATE(), 101)
				AND I.LoadSuccess = 0	
			 )
	BEGIN 
			
		
		EXEC [$(ETLDB)].dbo.spQueryToHtmlTable @html = @html OUTPUT,  
		@query = N'SELECT F.*, I.LoadSuccess 
				   FROM Sample_Audit.dbo.files F
				   INNER JOIN Sample_Audit.dbo.IncomingFiles I ON F.AuditID = I.AuditID
				   WHERE F.FileName LIKE ''IPSOS_Franchise_Report_%''
				   AND CONVERT(DATE, F.ActionDate, 101) = CONVERT(DATE, GETDATE(), 101)
				   AND I.LoadSuccess = 0', 
		@orderBy = N'ORDER BY 1';
		
		DECLARE @Subject nvarchar(MAX);
		SET @Subject = 'Todays dowloaded FIMs hierarchy file failed to load. Please check format.';

		--v1.1
		IF @@ServerName = '1005796-CXNSQLP'
		BEGIN
			SET @EmailRecipients = 'ben.king@ipsos.com; Eddie.Thomas@ipsos.com; Chris.Ledger@ipsos.com;Dipak.Gohil@ipsos.com'
		END
	ELSE
		BEGIN
			SET @EmailRecipients = 'ben.king@ipsos.com;Chris.ledger@ipsos.com;Eddie.Thomas@ipsos.com'
		END	


		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'DBAProfile',
			@recipients = @EmailRecipients,
			@subject = @Subject, 
			@body = @html,
			@body_format = 'HTML',
			@from_address = 'CNX_JLR_Output@ipsos-online.com'

			RAISERROR ('FIMs Fail', 20, 127) WITH LOG
	END


	IF NOT EXISTS (
					SELECT * 
					FROM [$(AuditDB)].dbo.Files F											
					INNER JOIN [$(AuditDB)].dbo.IncomingFiles I ON F.AuditID = I.AuditID
					WHERE F.FileName LIKE 'IPSOS_Franchise_Report_%'
					AND CONVERT(DATE, F.ActionDate, 101) = CONVERT(DATE, GETDATE(), 101)	
				   )
	BEGIN 
		
		SET @Subject = 'Todays FIMs hierarchy file was not available to download!';

		--v1.1
		IF @@ServerName = '1005796-CXNSQLP'
		BEGIN
			SET @EmailRecipients = 'um-tcs-sxp@jaguarlandrover.com;aaggarw6@partner.jaguarlandrover.com;ben.king@ipsos.com; Eddie.Thomas@ipsos.com; Chris.Ledger@ipsos.com;Dipak.Gohil@ipsos.com'
		END
	ELSE
		BEGIN
			SET @EmailRecipients = 'ben.king@ipsos.com;Chris.ledger@ipsos.com;Eddie.Thomas@ipsos.com'
		END	

		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'DBAProfile',
			@recipients = @EmailRecipients,
			@subject = @Subject, 
			--@body = @html,
			--@body_format = 'HTML',
			@from_address = 'CNX_JLR_Output@ipsos-online.com'

			RAISERROR ('FIMs Fail', 20, 127) WITH LOG
			
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

