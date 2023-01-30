CREATE PROCEDURE [CustomerUpdate].[uspExtraVehicleFeed_DownloadCheck]
AS
SET NOCOUNT ON

/*
	Purpose:	Email Alert - Extra Vehicle Feed File Not Received
			
	Release		Version			Date			Developer			Comment
	LIVE		1.1				2022-08-08      Chris Ledger		Task 985 - Send email alert if there is no EVF file
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY

	DECLARE @HTML NVARCHAR(MAX);
	DECLARE @EmailRecipients NVARCHAR(250);
	DECLARE @Subject NVARCHAR(MAX);


	IF NOT EXISTS (	SELECT * 
					FROM [$(AuditDB)].dbo.Files F											
						INNER JOIN [$(AuditDB)].dbo.IncomingFiles I ON F.AuditID = I.AuditID
					WHERE F.FileName LIKE 'CQI_VEHICLE_EXPORT%'
						AND CAST(F.ActionDate AS DATE) = CAST(GETDATE() AS DATE))

		BEGIN 
			
			SET @Subject = 'No CQI Vehicle Export File Downloaded Today - ' + CONVERT(VARCHAR,GETDATE(),23);

			IF @@ServerName = '1005796-CXNSQLP'
				BEGIN
					SET @EmailRecipients = 'David.Walker@ipsos.com;Louisa.Tassell@ipsos.com;Vladimir.Hodan@ipsos.com;Alex.Gordon@ipsos.com;ben.king@ipsos.com;Chris.ledger@ipsos.com;Eddie.Thomas@ipsos.com'
				END
			ELSE
				BEGIN
					SET @EmailRecipients = 'ben.king@ipsos.com;Chris.ledger@ipsos.com;Eddie.Thomas@ipsos.com'
				END	

			EXEC msdb.dbo.sp_send_dbmail
				@profile_name = 'DBAProfile',
				@recipients = @EmailRecipients,
				@subject = @Subject, 
				--@body = @HTML,
				--@body_format = 'HTML',
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

