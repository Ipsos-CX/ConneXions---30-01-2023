CREATE PROCEDURE Load.uspOvernightSampleLoadJobFailureEmail

AS

/*
	Purpose:	New SP to email developers of any overnight load failures
	
	Version			Date				Developer			Comment
	1.0				2016-12-13			Chris Ledger		New SP to email developers of any overnight load failures
	1.1				2019-04-11			Chris Ross			BUG 15345 - Update to use IPSOS email addresses.
	1.2				2019-07-25			Chris Ledger		Change sj.job_id to sj.name
	1.3				2020-01-10			Chris Ledger		BUG 15372 - Fix Hard coded references to databases
	1.4				2020-03-09			Chris Ledger		BUG 16934 - Include "Archive Package Logs" now it doesn't error every day
	1.5				2021-05-25			Chris Ledger		Exclude "Archive Package Logs" and remove Chris.Ross@ipsos.com
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
    DECLARE @Subject NVARCHAR(MAX) = 'Overnight Sample Load Job Failure Report: ' + CONVERT(VARCHAR(10),GETDATE(),103);
    --DECLARE @To NVARCHAR(MAX) = 'Chris.Ledger@ipsos.com';
    DECLARE @To NVARCHAR(MAX) = 'Chris.Ledger@ipsos.com;Ben.King@ipsos.com;Eddie.Thomas@ipsos.com';		-- V1.5
    DECLARE @Profile_Name SYSNAME = 'DBAProfile';
 
	--------------------------------------------------------
	-- RESET @RunStatus IF ANY STEPS FAILED (I.E. run_status = 0)
	--------------------------------------------------------	
	SELECT TOP 1 @RunStatus = sjh.run_status 
	FROM msdb.dbo.sysjobhistory sjh 
	INNER JOIN msdb.dbo.sysjobs sj ON sj.job_id=sjh.job_id
	WHERE run_date = CONVERT(INT,CONVERT(VARCHAR(8),GETDATE(),112))
	AND sj.name = 'Sample Load and Selection'
	AND sjh.run_status = 0
	--AND sjh.step_name <> 'Archive Package Logs'	-- V1.4
	--------------------------------------------------------

	--------------------------------------------------------
	-- CREATE HTML OUPUT
	--------------------------------------------------------
	SET @tableHTML =  	
		N'<H3 style ="font-size:12px; font-family:arial,helvetica,sans-serif; font-weight:normal; text-align:left; background:#ffffff;">The following overnight load steps failed:-</H3>' +
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
			AND sj.name = 'Sample Load and Selection'
			AND sjh.run_status = 0
			AND sjh.step_name <> 'Archive Package Logs' -- V1.4	-- V1.5
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

