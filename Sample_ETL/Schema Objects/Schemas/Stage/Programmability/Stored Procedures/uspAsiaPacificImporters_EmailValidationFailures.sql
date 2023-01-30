CREATE PROCEDURE Stage.uspAsiaPacificImporters_EmailValidationFailures

AS

/*
		Purpose:	Notify Execs of Asia Pacific Importers Responses Validation Failures
			
		Version		Date			Developer			Comment
LIVE	1.0			2021-10-29		Chris Ledger		Task 598: notify execs of validation failures
LIVE	1.1			2022-04-08		Chris Ledger		Task 850: add Invalid Model for Dealer validation reason
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
			SET @EmailRecipients = 'chris.ledger@ipsos.com;andrew.erskine@ipsos.com;sjayara8@jaguarlandrover.com;okuhn@partner.jaguarlandrover.com'
		END
	ELSE
		BEGIN
			SET @EmailRecipients = 'chris.ledger@ipsos.com'
		END	


	IF EXISTS (	SELECT * 
				FROM Stage.AsiaPacificImporters API
				WHERE ISNULL(API.ValidatedData,0) = 0)

	BEGIN 		
		
		EXEC dbo.spQueryToHtmlTable @html = @html OUTPUT,  
			@query = N'SELECT F.FileName AS [File Name],
						API.PhysicalRowID AS Row,
						STUFF((CASE	WHEN API.EventTypeID IS NULL THEN '',  Invalid Event Type: '' + CAST(API.e_jlr_event_type_id_enum AS NVARCHAR)
									ELSE '''' END
							+ CASE	WHEN API.CountryID IS NULL THEN '',  Invalid Country: '' + CAST(API.e_jlr_country_name_auto AS NVARCHAR)
									ELSE '''' END
							+ CASE WHEN API.LanguageID IS NULL THEN '',  Invalid Language: '' + CAST(API.e_jlr_language_id_enum AS NVARCHAR)
									ELSE '''' END 
							+ CASE	WHEN API.ModelID IS NULL THEN '',  Unknown Model: (VIN = '' + REPLACE(API.e_jlr_vehicle_identification_number_text,''*'','''') + '')''
									ELSE '''' END 
							+ CASE	WHEN API.OutletPartyID IS NULL THEN '',  Uncoded Dealer: '' + API.e_jlr_dealer_name_auto + '' ('' + API.e_jlr_country_name_auto + '')''
									ELSE '''' END
							+ CASE WHEN API.ModelID IS NOT NULL AND API.OutletPartyID IS NOT NULL AND API.ManufacturerPartyID IS NULL THEN '',  Invalid Model for Dealer''
									ELSE '''' END), 1, 3, '''') AS [Reasons for Non-Validation]
						FROM Sample_ETL.Stage.AsiaPacificImporters API
							LEFT JOIN Sample_Audit.dbo.Files F ON API.AuditID = F.AuditID
						WHERE ISNULL(API.ValidatedData,0) = 0', 
			@orderBy = N'ORDER BY 1';
		
		SET @Subject = 'Asia Pacific Importer Responses Failed Validation: ' + SUBSTRING(CONVERT(VARCHAR,GETDATE(),120),1,LEN(CONVERT(VARCHAR,GETDATE(),120))-3);

		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'DBAProfile',
			@recipients = @EmailRecipients,
			@subject = @Subject, 
			@body = @html,
			@body_format = 'HTML',
			@from_address = 'CNX_JLR_Output@ipsos-online.com'
	END


	IF EXISTS (	SELECT * 
				FROM Stage.AsiaPacificImporters API
				WHERE ISNULL(API.ValidatedData,0) = 1)

	BEGIN 		
		
		EXEC dbo.spQueryToHtmlTable @html = @html OUTPUT,  
		@query = N' SELECT F.FileName,
						COUNT(*) AS COUNT
					FROM Sample_ETL.Stage.AsiaPacificImporters API
						LEFT JOIN Sample_Audit.dbo.Files F ON API.AuditID = F.AuditID
					WHERE ISNULL(API.ValidatedData,0) = 1
					GROUP BY F.FileName', 
		@orderBy = N'ORDER BY 1';
		
		
		SET @Subject= 'Asia Pacific Importer Responses Successfully Loaded: ' + SUBSTRING(CONVERT(VARCHAR,GETDATE(),120),1,LEN(CONVERT(VARCHAR,GETDATE(),120))-3);

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