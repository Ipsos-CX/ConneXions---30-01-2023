CREATE PROCEDURE [SampleReport].[uspReportCRCGlobalListErrors]
AS
SET NOCOUNT ON

/*
	Purpose:	Reports data 
			
	Release		Version			Date			Developer			Comment
	UAT			1.0				21/04/2022		Eddie Thomas		TASK 841

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
				SELECT * FROM [$(ETLDB)].[Stage].[CRCAgents_GlobalList]
				WHERE IP_DataErrorDescription IS NOT NULL
			  )

	BEGIN 
			
		
		EXEC [$(ETLDB)].dbo.spQueryToHtmlTable @html = @html OUTPUT,  
		@query = N'SELECT 
					  [CDSID]
					  ,[FirstName]
					  ,[Surname]
					  ,[DisplayOnQuestionnaire]
					  ,[DisplayOnWebsite]
					  ,[FullName]
					  ,[Market]
					  ,[MarketCode]				  
					FROM [Sample_ETL].[Stage].[CRCAgents_GlobalList]
					WHERE [IP_DataErrorDescription] IS NOT NULL', 
		@orderBy = N'ORDER BY 1';
		
		DECLARE @Subject nvarchar(MAX);
		SET @Subject = 'CRC Agents List load errors - Fix and reload file';

		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'DBAProfile',
			@recipients = @EmailRecipients, --V1.1
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


