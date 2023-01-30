CREATE PROCEDURE [SampleReport].[uspReportFranchiseFileError]
AS
SET NOCOUNT ON

/*
	Purpose:	Notify Execs of Franchise Data Errors
			
	Release			Version			Date			Developer			Comment
	LIVE			1.0				18/05/2021		Ben King			Creation BUG 18055
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
			SET @EmailRecipients = 'ben.king@ipsos.com; Eddie.Thomas@ipsos.com; Chris.Ledger@ipsos.com;Dipak.Gohil@ipsos.com; Pia.Forslund@ipsos.com'
		END
	ELSE
		BEGIN
			SET @EmailRecipients = 'ben.king@ipsos.com;Chris.ledger@ipsos.com;Eddie.Thomas@ipsos.com'
		END	

	IF EXISTS (SELECT *
					FROM [$(ETLDB)].DealerManagement.Franchises_Load
					WHERE IP_DataError IS NOT NULL)

	BEGIN 
			
		DECLARE @html nvarchar(MAX);
		EXEC [$(ETLDB)].dbo.spQueryToHtmlTable @html = @html OUTPUT,  
		@query = N'SELECT IP_DataError, [10CharacterCode],FranchiseCountry, FranchiseType
				   FROM Sample_ETL.DealerManagement.Franchises_Load WHERE IP_DataError IS NOT NULL', 
		@orderBy = N'ORDER BY 1';
		
		DECLARE @Subject nvarchar(MAX);
		SET @Subject = 'REJECTED JLR FRANCHISE RECORDS. FILE: "' + (SELECT DISTINCT ImportFileName FROM [$(ETLDB)].DealerManagement.Franchises_Load) + '".  (Review Data Errors)';

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
