CREATE PROCEDURE Load.uspCRMResponseJobFailureEmail

AS

/*
	Purpose:	New SP to email developers of any CRM response download failures
	
	Version			Date				Developer			Comment
	1.0				2018-04-17			Chris Ledger		New SP to email developers of any CRM response download failures
	1.1				2019-04-11			Chris Ross			BUG 15345 - Update to use IPSOS email addresses.
	1.2				2019-04-29			Chris Ledger		BUG 15345 - Change Job Name
	1.3				2019-05-02			Chris Ross			BUG 15371 - Include Dipak in email list.
	1.4				2020-01-10			Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	DECLARE @tableHTML  NVARCHAR(MAX);
	DECLARE @RunStatus  INT = 1;
    DECLARE @Subject NVARCHAR(MAX) = 'CRM - Response Download and Output Job Failure Report: ' + CONVERT(VARCHAR(10),GETDATE(),103);
    --DECLARE @To NVARCHAR(MAX) = 'Chris.Ledger@ipsos.com';
    DECLARE @To NVARCHAR(MAX) = 'Dipak.Gohil@ipsos.com;Chris.Ledger@ipsos.com;Ben.King@ipsos.com;Eddie.Thomas@ipsos.com;Chris.Ross@ipsos.com';		-- v1.3
    DECLARE @Profile_Name SYSNAME = 'DBAProfile';
 
	--------------------------------------------------------
	-- RESET @RunStatus IF ANY STEPS FAILED (I.E. run_status = 0)
	--------------------------------------------------------	
	SELECT TOP 1 @RunStatus = sjh.run_status 
	FROM msdb.dbo.sysjobhistory sjh 
	INNER JOIN msdb.dbo.sysjobs sj ON sj.job_id=sjh.job_id
	WHERE run_date = CONVERT(INT,CONVERT(VARCHAR(8),GETDATE(),112))
	AND sj.name = 'CRM - Response Download and Output of SC115  (includes Customer Updates pre-step)'		-- V1.2
	AND sjh.run_status = 0
	--------------------------------------------------------

	--------------------------------------------------------
	-- CREATE HTML OUPUT
	--------------------------------------------------------
	SET @tableHTML =  	
		N'<H3 style ="font-size:12px; font-family:arial,helvetica,sans-serif; font-weight:normal; text-align:left; background:#ffffff;">The following CRM - Response Download and Output steps failed:-</H3>' +
		N'<table border="0" align="left" cellpadding="2" cellspacing="0" style="color:black;font-family:arial,helvetica,sans-serif;text-align:left;" >' +
		N'<tr style ="font-size:12px; font-weight:bold; text-align:left; background:#ffffff;"><td style="width:300px">Step</td>' +  
		N'<td></td></tr>' +  
		CAST ( ( SELECT 'font-size:12px; font-weight:normal; text-align:left; background:#ffffff' as [@style], td = sjh.step_name, '',
			CASE sjh.run_status 
			WHEN 0 THEN 'Failed'
			WHEN 1 THEN 'Pass'
			WHEN 2 THEN 'Retry'
			WHEN 3 THEN 'Cancel'
			END AS td
			FROM msdb.dbo.sysjobhistory sjh 
			INNER JOIN msdb.dbo.sysjobs sj ON sj.job_id=sjh.job_id
			WHERE run_date = CONVERT(INT,CONVERT(VARCHAR(8),GETDATE(),112))
			AND sj.name = 'CRM - Response Download and Output of SC115  (includes Customer Updates pre-step)'		-- V1.2
			AND sjh.run_status = 0
			FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX) ) +  
		N'</table>' ;  
	--------------------------------------------------------
    
	--------------------------------------------------------
	-- SEND EMAIL IF FAILURES 
	--------------------------------------------------------
	IF @RunStatus = 0
	BEGIN
		EXEC msdb.dbo.sp_send_dbmail @profile_name = @Profile_Name,
			@recipients = @To, @subject = @Subject, @body = @tableHTML, @body_format = 'HTML';
	END
	--------------------------------------------------------

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