CREATE PROCEDURE [SampleReport].[uspReportUnmatched10DigCode]
AS
SET NOCOUNT ON

/*
	Purpose:	Notify Execs of Franchise Data Errors
			
	Release			Version			Date			Developer			Comment
	LIVE			1.0				18/05/2021		Ben King			Creation BUG 18153
	LIVE			1.1				11/01/2022		Ben King			TASK 738 General Tidy up of solution
	LIVE			1.2     		28/10/2022		Ben King			TASK 1053 - 19616 - Sample Health - clear out reasons for non selections for duplicates
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
			SET @EmailRecipients = 'ben.king@ipsos.com; Eddie.Thomas@ipsos.com; Chris.Ledger@ipsos.com;Dipak.Gohil@ipsos.com'
		END
	ELSE
		BEGIN
			SET @EmailRecipients = 'ben.king@ipsos.com;Chris.ledger@ipsos.com;Eddie.Thomas@ipsos.com'
		END	

	IF EXISTS (SELECT * 
	           FROM SampleReport.IndividualRowsCombined -- V1.2
               WHERE Questionnaire NOT IN ('CRC', 'Roadside','CRC General Enquiry') 
			   AND UncodedDealer = 0 
			   AND LEN(ISNULL(Dealer10DigitCode,'')) = 0
			   AND CONVERT(DATE,ReportDate) = CONVERT(DATE,GETDATE()))

	BEGIN 
			
		DECLARE @html nvarchar(MAX);
		EXEC [$(ETLDB)].dbo.spQueryToHtmlTable @html = @html OUTPUT,  
		@query = N'SELECT 
						Market, 
						Questionnaire, 
						COUNT(CaseID) AS [Matched Dealer - Selected - Blank Dealer10DigitCode], 
						COUNT(Market) - COUNT(CaseID) As [Matched Dealer - Not Selected - Blank Dealer10DigitCode]
				FROM SampleReporting.SampleReport.IndividualRowsCombined
				WHERE CONVERT(DATE,ReportDate) = CONVERT(DATE,GETDATE())
				AND UncodedDealer = 0 
				AND LEN(ISNULL(Dealer10DigitCode,'''')) = 0
				AND Questionnaire NOT IN (''CRC'', ''Roadside'',''CRC General Enquiry'')
				GROUP BY Market,Questionnaire', 
		@orderBy = N'ORDER BY 1';
		
		DECLARE @Day nvarchar(MAX);
		SET @Day = 'Sample Reporting - Medaliia - Blank Dealer 10 Digit Code records removed. Investigate';

		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'DBAProfile',
			@recipients = @EmailRecipients, --v1.1
			@subject = @Day, 
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
