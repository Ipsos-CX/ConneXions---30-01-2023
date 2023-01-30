CREATE PROCEDURE [Stage].[uspReportMisalignedRecords]

AS
SET NOCOUNT ON

/*
	Purpose:	Alter contact preferences by PID
			
	Release			Version			Date			Developer			Comment
	LIVE			1.0				23/04/2019		Ben King			Creation BUG 15311 (UAT)
	LIVE			1.1				10/01/2020		Chris Ledger		Set @recipients to match LIVE
	LIVE			1.2				10/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
	LIVE			1.3				11/01/2022		Ben King			TASK 738 General Tidy up of solution
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY

	DECLARE @EmailRecipients nvarchar(250);

	--V1.1
	IF @@ServerName = '1005796-CXNSQLP'
		BEGIN
			SET @EmailRecipients = 'Andrew.Erskine@ipsos.com; Pia.Forslund@ipsos.com; ben.king@ipsos.com; Eddie.Thomas@ipsos.com; Chris.Ledger@ipsos.com; Dipak.Gohil@ipsos.com'
		END
	ELSE
		BEGIN
			SET @EmailRecipients = 'ben.king@ipsos.com;Chris.ledger@ipsos.com;Eddie.Thomas@ipsos.com'
		END	

	IF Exists( 
				SELECT	 *
				FROM	 [Stage].[Removed_Records_Staging_Tables]
				WHERE	 [EmailSent] IS NULL
			)			 
	BEGIN
		DECLARE @html nvarchar(MAX);
		EXEC dbo.spQueryToHtmlTable @html = @html OUTPUT,  @query = N'SELECT AuditID AS [Audit ID], FileName AS [FileName], convert(varchar(10), ActionDate, 120) AS [Loaded date], PhysicalFileRow AS [File row], VIN AS [VIN], Misaligned_ModelYear AS [Misaligned ModelYear] FROM [Stage].[Removed_Records_Staging_Tables] WHERE [EmailSent] IS NULL', @orderBy = N'ORDER BY [Audit ID]';

		EXEC msdb.dbo.sp_send_dbmail
		   @profile_name = 'DBAProfile',
		   --@recipients = 'Chris.Ledger@ipsos.com;;ben.king@ipsos.com',
		   @recipients = @EmailRecipients, --V1.3
		   @subject = 'Misaligned records removed from overnight load',
		   @body = @html,
		   @body_format = 'HTML'

		UPDATE [Stage].[Removed_Records_Staging_Tables]
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