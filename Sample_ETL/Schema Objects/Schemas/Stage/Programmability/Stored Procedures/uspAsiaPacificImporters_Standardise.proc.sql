CREATE PROCEDURE Stage.uspAsiaPacificImporters_Standardise

AS

/*
		Purpose:	Convert the supplied dates from a text string to a valid DATETIME type
	
		Version		Date			Developer			Comment
LIVE	1.0			2021-10-11		Chris Ledger		Created
LIVE	1.1			2021-11-29		Chris Ledger		Task 598 - recode q_jlr_service_days_vehicle_seen_alt DK from 99 to 33.
*/


DECLARE @ErrorNumber			INT

DECLARE @ErrorSeverity			INT
DECLARE @ErrorState				INT
DECLARE @ErrorLocation			NVARCHAR(500)
DECLARE @ErrorLine				INT
DECLARE @ErrorMessage			NVARCHAR(2048)

SET LANGUAGE ENGLISH
BEGIN TRY

	---------------------------------------------------------------------------------------------------------
	-- V1.1 Recode q_jlr_service_days_vehicle_seen_alt DK from 99 to 33  
	---------------------------------------------------------------------------------------------------------
	UPDATE API SET API.q_jlr_service_days_vehicle_seen_alt = '33'
	FROM Stage.AsiaPacificImporters API
	WHERE API.q_jlr_service_days_vehicle_seen_alt = '99'
	---------------------------------------------------------------------------------------------------------	

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
		
	-- CREATE A COPY OF THE STAGING TABLE FOR USE IN PRODUCTION SUPPORT
	DECLARE @TimestampString CHAR(15)
	SELECT @TimestampString = [$(ErrorDB)].dbo.udfGetTimestampString(GETDATE())
	
	EXEC('
		SELECT *
		INTO [$(ErrorDB)].Stage.AsiaPacificImporters_' + @TimestampString + '
		FROM Stage.AsiaPacificImporters
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH
