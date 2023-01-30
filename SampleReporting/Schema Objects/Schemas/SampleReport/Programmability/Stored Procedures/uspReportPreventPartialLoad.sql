CREATE PROCEDURE [SampleReport].[uspReportPreventPartialLoad]
AS
SET NOCOUNT ON

/*
	Purpose:	Alter contact preferences by PID
			
	Release			Version			Date			Developer			Comment
	LIVE			1.0             13/05/2021      Ben King            BUG 18200 - Belgium Service Loader - Remove Non-applicable countryCodes
	LIVE			1.1				11/01/2022		Ben King			TASK 738 General Tidy up of solution
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY

	--V1.1
	DECLARE @EmailRecipients nvarchar(250);

	IF @@ServerName = '1005796-CXNSQLP'
		BEGIN
			SET @EmailRecipients = 'Andrew.Erskine@ipsos.com; ben.king@ipsos.com; Eddie.Thomas@ipsos.com; Chris.Ledger@ipsos.com; Dipak.Gohil@ipsos.com'
		END
	ELSE
		BEGIN
			SET @EmailRecipients = 'ben.king@ipsos.com;Chris.ledger@ipsos.com;Eddie.Thomas@ipsos.com'
		END	


	IF Exists( 
				SELECT	 *
				FROM	 [$(ETLDB)].[dbo].[Removed_Records_Prevent_PartialLoad]
				WHERE	 [EmailSent] IS NULL
			)			 
	BEGIN
		DECLARE @html nvarchar(MAX);
		EXEC [$(ETLDB)].dbo.spQueryToHtmlTable @html = @html OUTPUT,  @query = N'SELECT AuditID AS [Audit ID], FileName AS [FileName], convert(varchar(10), ActionDate, 120) AS [Loaded date], PhysicalFileRow AS [File row], VIN AS [VIN], [CountryCode], [RemovalReason] FROM [Sample_ETL].[dbo].[Removed_Records_Prevent_PartialLoad] WHERE [EmailSent] IS NULL', @orderBy = N'ORDER BY [Audit ID]';

		EXEC msdb.dbo.sp_send_dbmail
		   @profile_name = 'DBAProfile',
		   --@recipients = 'Chris.Ledger@ipsos.com;;ben.king@ipsos.com',
		   @recipients = @EmailRecipients, --V1.1
		   @subject = 'Removed Sample - Prevent partial load',
		   @body = @html,
		   @body_format = 'HTML'

		UPDATE [$(ETLDB)].[dbo].[Removed_Records_Prevent_PartialLoad]
		SET    [EmailSent] = GETDATE()
		WHERE  [EmailSent] IS NULL
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
