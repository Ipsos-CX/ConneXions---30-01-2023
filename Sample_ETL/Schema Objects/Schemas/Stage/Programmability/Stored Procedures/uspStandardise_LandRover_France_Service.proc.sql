CREATE PROCEDURE Stage.uspStandardise_LandRover_France_Service 
AS

/*
	Purpose:	Convert the service date from a text string to a valid DATETIME type
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspSTANDARDISE_STAGE_Landrover_France_Aftersales_Dates

*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

SET LANGUAGE ENGLISH
SET DATEFORMAT DMY

BEGIN TRY

	UPDATE Stage.LandRover_France_Service
	SET ConvertedServiceEventDate = CAST(ServiceEventDate AS DATETIME2)
	WHERE ISDATE(ServiceEventDate) = 1
	
	UPDATE Stage.LandRover_France_Service
	SET ConvertedRegistrationDate = CAST(RegistrationDate AS DATETIME2)
	WHERE ISDATE(RegistrationDate) = 1

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
		INTO [$(ErrorDB)].Stage.LandRover_France_Service_' + @TimestampString + '
		FROM Stage.LandRover_France_Service
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @Errornumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
	
END CATCH

