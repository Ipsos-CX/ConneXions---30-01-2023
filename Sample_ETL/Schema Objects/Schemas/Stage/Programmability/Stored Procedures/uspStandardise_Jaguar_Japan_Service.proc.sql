
CREATE PROCEDURE Stage.uspStandardise_Jaguar_Japan_Service
AS

/*
	Purpose:	Convert the service date from a text string to a valid DATETIME type
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspSTANDARDISE_STAGE_Jaguar_Japan_Service

*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

SET LANGUAGE ENGLISH
SET DATEFORMAT YMD

BEGIN TRY

	UPDATE Stage.Jaguar_Japan_Service
	SET ConvertedServiceEventDate = CONVERT( DATETIME, STUFF(STUFF(ServiceEventDate,3,0,'-'),6,0,'-' ))
	WHERE isdate ( SUBSTRING( ServiceEventDate, 1, 2) 
	             + '/' 
	             + SUBSTRING( ServiceEventDate, 3, 2) 
	             + '/' 
	             + SUBSTRING( ServiceEventDate, 5, 2) ) = 1
	AND LEN(ServiceEventDate) = 6
		--
	-- This is to stop loading data where the date conversion has errors
	--
	SELECT	CONVERT( DATETIME, STUFF(STUFF(ServiceEventDate,3,0,'-'),6,0,'-' ))
    FROM    Stage.Jaguar_Japan_Service
	WHERE   ISDATE ( SUBSTRING( ServiceEventDate, 1, 2) 
	               + '/' 
	               + SUBSTRING( ServiceEventDate, 3, 2) 
	               + '/' 
	               + SUBSTRING( ServiceEventDate, 5, 2) ) = 0
	AND LEN(ServiceEventDate) = 6

	
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
		INTO [$(ErrorDB)].Stage.Jaguar_Japan_Service_' + @TimestampString + '
		FROM Stage.Jaguar_Japan_Service
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
END CATCH