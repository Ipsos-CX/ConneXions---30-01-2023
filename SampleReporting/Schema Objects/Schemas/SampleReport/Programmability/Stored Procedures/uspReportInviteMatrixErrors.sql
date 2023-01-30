

CREATE PROCEDURE [SampleReport].[uspReportInviteMatrixErrors]
AS
SET NOCOUNT ON

/*
	Purpose:	Reports data errros and flags missing Core Markets
			
	Release			Version			Date			Developer			Comment
	LIVE			1.0				19112021		Ben King			TASK 690
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

	--V1.1
	DECLARE @EmailRecipients nvarchar(250);

	IF @@ServerName = '1005796-CXNSQLP'
		BEGIN
			SET @EmailRecipients = 'ben.king@ipsos.com; Eddie.Thomas@ipsos.com; Chris.Ledger@ipsos.com;Dipak.Gohil@ipsos.com; Andrew.Erskine@ipsos.com'
		END
	ELSE
		BEGIN
			SET @EmailRecipients = 'ben.king@ipsos.com; Eddie.Thomas@ipsos.com; Chris.Ledger@ipsos.com'
		END	

	IF EXISTS (
				SELECT * FROM [$(ETLDB)].[Stage].[InviteMatrix]
				WHERE IP_DataError IS NOT NULL
			  )

	BEGIN 
			
		
		EXEC [$(ETLDB)].dbo.spQueryToHtmlTable @html = @html OUTPUT,  
		@query = N'SELECT
						IP_DataError,
						Brand,
						Market,
						Questionnaire,
						EmailLanguage
					FROM [Sample_ETL].[Stage].[InviteMatrix]
					WHERE IP_DataError IS NOT NULL', 
		@orderBy = N'ORDER BY 1';
		
		DECLARE @Subject nvarchar(MAX);
		SET @Subject = 'Invite Matrix load errors - Fix and reload file';

		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'DBAProfile',
			@recipients = @EmailRecipients, --V1.1
			@subject = @Subject, 
			@body = @html,
			@body_format = 'HTML',
			@from_address = 'CNX_JLR_Output@ipsos-online.com'
	END


	IF EXISTS (
				SELECT * FROM [$(SampleDB)].dbo.Markets mk
				WHERE mk.Market NOT IN (SELECT Market FROM [$(ETLDB)].[Stage].[InviteMatrix])
				AND MK.FranchiseCountryType = 'Core'
			  )

	BEGIN 
			
		
		EXEC [$(ETLDB)].dbo.spQueryToHtmlTable @html = @html OUTPUT,  
		@query = N'SELECT Market, MarketID, CountryID
					FROM Sample.dbo.Markets mk
					WHERE mk.Market NOT IN (SELECT Market FROM Sample_ETL.[Stage].[InviteMatrix])
					AND MK.FranchiseCountryType = ''Core''', 
		@orderBy = N'ORDER BY 1';
		
		
		SET @Subject = 'Invite Matrix - Following Core markets not in loaded file';

		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'DBAProfile',
			@recipients = @EmailRecipients,
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