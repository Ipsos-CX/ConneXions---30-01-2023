

CREATE PROCEDURE Stage.uspStandardise_LandRover_Russia_Service
AS

/*
	Purpose:	Convert the service date from a text string to a valid DATETIME type
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspSTANDARDISE_STAGE_LandRover_Russia_Service

*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

SET LANGUAGE ENGLISH
SET DATEFORMAT DYM

BEGIN TRY

	UPDATE	Stage.LandRover_Russia_Service
	SET		ConvertedEventDate = CONVERT( DATETIME, LTRIM(RTRIM((EventDate))))
	WHERE	ISDATE ( LTRIM(RTRIM(EventDate ))) = 1
	AND		LEN(LTRIM(RTRIM(EventDate))) = 10
	--
	-- This is to stop loading data where the date conversion has errors
	--
	SELECT	CONVERT( DATETIME, LTRIM(RTRIM(EventDate )))
    FROM    Stage.LandRover_Russia_Service
	WHERE   ISDATE ( LTRIM(RTRIM(EventDate ))) = 0
	AND LEN(EventDate) = 10
	
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
		INTO [$(ErrorDB)].Stage.LandRover_Russia_Service_' + @TimestampString + '
		FROM Stage.LandRover_Russia_Service
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
END CATCH