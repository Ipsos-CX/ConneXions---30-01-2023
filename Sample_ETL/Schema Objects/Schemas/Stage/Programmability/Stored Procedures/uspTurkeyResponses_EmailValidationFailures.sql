CREATE PROCEDURE Stage.uspTurkeyResponses_EmailValidationFailures

AS

/*
		Purpose:	Notify Execs of Turkey Responses Validation Failures
			
		Version		Date			Developer			Comment
LIVE	1.0			2021-10-29		Chris Ledger		Task 598: notify execs of validation failures
LIVE	1.1			2022-01-20		Chris Ledger		Task 766: correct kerem.bayram@borusanotomotiv.com email address
LIVE	1.2			2022-04-08		Chris Ledger		Task 850: add Invalid Model for Dealer validation reason
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY

	DECLARE @html nvarchar(MAX);
	DECLARE @Subject nvarchar(MAX);
	DECLARE @EmailRecipients nvarchar(250);

	IF @@ServerName = '1005796-CXNSQLP'
		BEGIN
			SET @EmailRecipients = 'chris.ledger@ipsos.com;andrew.erskine@ipsos.com;Eylul.ersan@borusanotomotiv.com;kerem.bayram@borusanotomotiv.com'		-- V1.1
		END
	ELSE
		BEGIN
			SET @EmailRecipients = 'chris.ledger@ipsos.com'
		END	


	IF EXISTS (	SELECT * 
				FROM Stage.TurkeyResponses TR
				WHERE ISNULL(TR.ValidatedData,0) = 0)

	BEGIN 		
		
		EXEC dbo.spQueryToHtmlTable @html = @html OUTPUT,  
			@query = N'SELECT F.FileName AS [File Name],
						TR.PhysicalRowID AS [Row],
						STUFF((CASE	WHEN TR.EventTypeID IS NULL THEN '',  Invalid Event Type: '' +  CAST(TR.e_jlr_event_type_id_enum AS NVARCHAR)
									ELSE '''' END
							+ CASE	WHEN TR.CountryID IS NULL THEN '',  Invalid Country: '' + CAST(TR.e_jlr_country_name_auto AS NVARCHAR)
									ELSE '''' END
							+ CASE WHEN TR.LanguageID IS NULL THEN '',  Invalid Language: '' + CAST(TR.e_jlr_language_id_enum AS NVARCHAR)
									ELSE '''' END 
							+ CASE	WHEN TR.ModelID IS NULL THEN '',  Unknown Model: (VIN = '' + REPLACE(TR.e_jlr_vehicle_identification_number_text,''*'','''') + '')''
									ELSE '''' END 
							+ CASE	WHEN TR.OutletPartyID IS NULL THEN '',  Uncoded Dealer: '' + TR.e_jlr_dealer_name_auto + '' ('' + TR.e_jlr_country_name_auto + '')''
									ELSE '''' END
							+ CASE WHEN TR.ModelID IS NOT NULL AND TR.OutletPartyID IS NOT NULL AND TR.ManufacturerPartyID IS NULL THEN '',  Invalid Model for Dealer''
									ELSE '''' END), 1, 3, '''') AS [Reasons for Non-Validation]
						FROM Sample_ETL.Stage.TurkeyResponses TR
							LEFT JOIN Sample_Audit.dbo.Files F ON TR.AuditID = F.AuditID
						WHERE ISNULL(TR.ValidatedData,0) = 0', 
			@orderBy = N'ORDER BY 1';
		
		SET @Subject = 'Turkey Responses Failed Validation: ' + SUBSTRING(CONVERT(VARCHAR,GETDATE(),120),1,LEN(CONVERT(VARCHAR,GETDATE(),120))-3);

		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'DBAProfile',
			@recipients = @EmailRecipients,
			@subject = @Subject, 
			@body = @html,
			@body_format = 'HTML',
			@from_address = 'CNX_JLR_Output@ipsos-online.com'
	END


	IF EXISTS (	SELECT * 
				FROM Stage.TurkeyResponses TR
				WHERE ISNULL(TR.ValidatedData,0) = 1)

	BEGIN 		
		
		EXEC dbo.spQueryToHtmlTable @html = @html OUTPUT,  
		@query = N' SELECT F.FileName AS [File Name],
						COUNT(*) AS [No. of Records Loaded]
					FROM Sample_ETL.Stage.TurkeyResponses TR
						LEFT JOIN Sample_Audit.dbo.Files F ON TR.AuditID = F.AuditID
					WHERE ISNULL(TR.ValidatedData,0) = 1
					GROUP BY F.FileName', 
		@orderBy = N'ORDER BY 1';	
		
		SET @Subject= 'Turkey Responses Successfully Loaded: ' + SUBSTRING(CONVERT(VARCHAR,GETDATE(),120),1,LEN(CONVERT(VARCHAR,GETDATE(),120))-3);

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