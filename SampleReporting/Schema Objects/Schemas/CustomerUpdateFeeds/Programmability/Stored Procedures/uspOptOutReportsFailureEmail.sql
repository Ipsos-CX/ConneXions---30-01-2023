CREATE PROCEDURE [CustomerUpdateFeeds].[uspOptOutReportsFailureEmail]

	/*

	Purpose: Generates email notification if the Opt out package fails
		
	Status	Version		Date			Developer			Comment
	LIVE	1.0			2021-01-14		Eddie Thomas		Created
	LIVE	1.1			2022-02-08		Chris Ledger		Set @EmailRecipients depending on server
	*/

	--ERROR MESSAGE DETAILS
	@MachineName		NVARCHAR(2000),			
	@ErrorCode			INT,	
	@ErrorDescription	NVARCHAR(MAX),
	@TaskFailure		VARCHAR(100)
		
	AS
		
	DECLARE 
			--LOCAL ERROR HANDLING
			@ErrorNumber			INT,
			@ErrorSeverity			INT,
			@ErrorState				INT,
			@ErrorLocation			NVARCHAR(500),
			@ErrorLine				INT,
			@ErrorMessage			NVARCHAR(2048),

			--EMAIL DETAILS
			@EmailSubject			NVARCHAR(2048),
			@EmailBody				NVARCHAR(MAX),
			@EmailRecipients		NVARCHAR(2048),
			@FromAddress			NVARCHAR(2048) = 'CNX_JLR_Output@ipsos-online.com'

	IF @@ServerName = '1005796-CXNSQLP'
		BEGIN
			SET @EmailRecipients = 'Eddie.Thomas@ipsos.com;dipak.gohil@ipsos.com;chris.ledger@ipsos.com;ben.king@ipsos.com'
		END
	ELSE
		BEGIN
			SET @EmailRecipients = 'Eddie.Thomas@ipsos.com'
		END	

	SET LANGUAGE ENGLISH
	BEGIN TRY
	
		IF @TaskFailure	= 'Archiving'	
			BEGIN
				SET @EmailSubject = N'SQL Job ' + CHAR(39) + 'Customer Update - Opt-Out Report' + CHAR(39) + ' (Archiving) has failed!'
				SET @EmailBody		= N'It wasn''t possible to generate the ''Opt Out'' reports, the preceding archive step failed. ' + CHAR(13) + CHAR(13) 

				--PRINT @EmailSubject
				--PRINT @EmailBody
			END
		ELSE IF @TaskFailure	= 'Reporting'
			BEGIN
				SET @EmailSubject	= 'SQL Job ' + CHAR(39) + 'Customer Update - Opt-Out Report' + CHAR(39) + ' (Report Output) has failed!'
				SET @EmailBody		= 'It wasn''t possible to generate the ''Opt Out'' reports, the export step failed. ' + CHAR(13) + CHAR(13)
			END
		ELSE IF @TaskFailure	= 'FTP'
			BEGIN
				SET @EmailSubject	= 'SQL Job ' + CHAR(39) + 'Customer Update - Opt-Out Report' + CHAR(39) + ' (FTP Upload) has failed!'	
				SET @EmailBody		= 'It wasn''t possible to upload to the MFT, the FTP step failed. ' + CHAR(13) + CHAR(13)
			END
		ELSE
			BEGIN
				SET @EmailSubject	= 'SQL Job ' + CHAR(39) + 'Customer Update - Opt-Out Report' + CHAR(39) + ' has failed!'	
				SET @EmailBody		= 'Information regarding the reason for failure can be seen below. ' + CHAR(13) + CHAR(13)
			END
		
		
		SET @EmailBody =	@EmailBody +	
							CHAR(9) + CHAR(9) + N'Machine Name : ' + @MachineName + CHAR(13) +
							CHAR(9) + CHAR(9) + N'Task Name : ' + @TaskFailure + CHAR(13) +
							CHAR(9) + CHAR(9) + N'Error Code : ' + CONVERT(NVARCHAR,@ErrorCode) + CHAR(13) +
							CHAR(9) + CHAR(9) + N'Error Description : ' + @ErrorDescription + CHAR(13) +
				
							'For further information please check the job history or the package logs.'


		EXEC msdb.dbo.sp_send_dbmail
			@profile_name	= 'DBAProfile',
			@recipients		= @EmailRecipients,
			@subject		= @EmailSubject, 
			@body			= @EmailBody,
			@from_address	= @FromAddress,
			@importance		= 'High'

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