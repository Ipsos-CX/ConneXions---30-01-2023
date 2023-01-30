CREATE PROCEDURE [SampleReport].[uspReportWeeklyWebsiteData]

AS
SET NOCOUNT ON

/*
	Purpose:	Notify Execs of Running of InMoment Export Report 
			
	Release			Version			Date			Developer			Comment
	LIVE			1.0				31/05/2019		Ben King			Creation BUG 15391
	LIVE			1.1				04/09/2019		Chris Ledger		Replace CNX_JLR_Output@gfk.com with CNX_JLR_Output@ipsos-online.com
	LIVE			1.2				15/01/2020		Chris Ledger 		BUG 15372 - Fix Hard coded references to databases
	LIVE			1.3				18/02/2020		Chris Ledger		BUG 17945 - Remove Andrea.Kennard@ipsos.com
	LIVE			1.4				11/01/2022		Ben King			TASK 738 General Tidy up of solution
	LIVE			1.5     		28/10/2022		Ben King			TASK 1053 - 19616 - Sample Health - clear out reasons for non selections for duplicates
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY

DECLARE @EmailRecipients nvarchar(250);

--V1.4
	IF @@ServerName = '1005796-CXNSQLP'
		BEGIN
			SET @EmailRecipients = 'Andrew.Erskine@ipsos.com; Pia.Forslund@ipsos.com; Ben.King@ipsos.com; Eddie.Thomas@ipsos.com; Chris.Ledger@ipsos.com; Dipak.Gohil@ipsos.com'
		END
	ELSE
		BEGIN
			SET @EmailRecipients = 'ben.king@ipsos.com;Chris.ledger@ipsos.com;Eddie.Thomas@ipsos.com'
		END	

	;WITH CountIssued (Mth, Brand, Questionnaire, Market, Loaded)
		AS
		 (
			 SELECT CONVERT(CHAR(6), LoadedDate, 112) AS Mth, Brand, Questionnaire, Market, COUNT(Market) AS Loaded
			 FROM SampleReport.IndividualRowsCombined -- V1.5
			 WHERE CONVERT(DATE, ReportDate) = CONVERT(DATE, GETDATE())
			 GROUP BY CONVERT(CHAR(6), LoadedDate, 112), Brand, Questionnaire, Market
		 ),
		 CountSent (Mth, Brand, Questionnaire, Market, SentSample)
		 AS
		 (
			 SELECT CONVERT(CHAR(6), LoadedDate, 112) AS Mth, Brand, Questionnaire, Market, COUNT(SentDate) AS SentSample
			 FROM SampleReport.IndividualRowsCombined -- V1.5
			 WHERE CONVERT(DATE, ReportDate) = CONVERT(DATE, GETDATE())
			 AND SentDate IS NOT NULL
			 GROUP BY CONVERT(CHAR(6), LoadedDate, 112), Brand, Questionnaire, Market
		 ),
		 CountInsert (Mth, Brand, Questionnaire, Market, RecordChanged)
		 AS
		 (
			 SELECT CONVERT(CHAR(6), LoadedDate, 112) AS Mth, Brand, Questionnaire, Market, COUNT(RecordChanged) AS RecordValueChange
			 FROM SampleReport.IndividualRowsCombined -- V1.5
			 WHERE CONVERT(DATE, ReportDate) = CONVERT(DATE, GETDATE())
			 AND RecordChanged = 1
			 GROUP BY CONVERT(CHAR(6), LoadedDate, 112), Brand, Questionnaire, Market
		 ),
		 CountResponded (Mth, Brand, Questionnaire, Market, RespondedSample)
		 AS
		 (
			 SELECT CONVERT(CHAR(6), LoadedDate, 112) AS Mth, Brand, Questionnaire, Market, COUNT(RespondedFlag) AS RespondedSample
			 FROM SampleReport.IndividualRowsCombined -- V1.5
			 WHERE CONVERT(DATE, ReportDate) = CONVERT(DATE, GETDATE())
			 AND RespondedFlag IS NOT NULL
			 GROUP BY CONVERT(CHAR(6), LoadedDate, 112), Brand, Questionnaire, Market
		 )
		 SELECT CONVERT(DATE,GETDATE()) AS DateRun, CI.Brand, CI.Market, CI.Questionnaire, CI.Loaded, ISNULL(CI.Loaded,0) - ISNULL(CIT.RecordChanged,0) AS New_Sample, CIT.RecordChanged, CS.SentSample, CR.RespondedSample  
		 INTO #results
		 FROM CountIssued CI
		 LEFT JOIN CountSent CS ON CI.Brand = CS.Brand
								AND CI.Mth = CS.Mth
								AND CI.Market = CS.Market
								AND CI.Questionnaire = CS.Questionnaire
		 LEFT JOIN CountResponded CR ON CI.Brand = CR.Brand
								AND CI.Mth = CR.Mth
								AND CI.Market = CR.Market
								AND CI.Questionnaire = CR.Questionnaire
		 LEFT JOIN CountInsert CIT ON CI.Brand = CIT.Brand
								AND CI.Mth = CIT.Mth
								AND CI.Market = CIT.Market
								AND CI.Questionnaire = CIT.Questionnaire
				 
	BEGIN
	
		DECLARE @html nvarchar(MAX);
		EXEC [$(ETLDB)].dbo.spQueryToHtmlTable @html = @html OUTPUT,  @query = N'SELECT * FROM #results', @orderBy = N'ORDER BY 4,3';
		
		DECLARE @Day nvarchar(MAX);
		SET @Day = DATENAME(weekday, GETDATE()) + 's InMoment Export Report';

		EXEC msdb.dbo.sp_send_dbmail
		   @profile_name = 'DBAProfile',
		   @recipients = @EmailRecipients, --V1.4
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