

CREATE PROCEDURE Stage.uspStandardise_LandRover_Portugal_Service 
AS

/*
	Purpose:	Convert the supplied dates from a text string to a valid DATETIME type
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspSTANDARDISE_STAGE_LandRover_Portugal_Service

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

	UPDATE Stage.LandRover_Portugal_Service
	SET ConvertedPurchaseDate = convert( datetime, STUFF(STUFF(PurchaseDate,3,0,'-'),6,0,'-'))
	WHERE isdate ( SUBSTRING( PurchaseDate, 1, 2) 
	             + '/' 
	             + SUBSTRING( PurchaseDate, 3, 2) 
	             + '/' 
	             + SUBSTRING( PurchaseDate, 5, 4) ) = 1
	AND LEN(PurchaseDate) = 8

	UPDATE Stage.LandRover_Portugal_Service
	SET ConvertedRegistrationDate = convert( datetime, STUFF(STUFF(RegistrationDate,3,0,'-'),6,0,'-'))
	WHERE isdate ( SUBSTRING( RegistrationDate, 1, 2) 
	             + '/' 
	             + SUBSTRING( RegistrationDate, 3, 2) 
	             + '/' 
	             + SUBSTRING( RegistrationDate, 5, 4) ) = 1
	AND LEN(RegistrationDate) = 8

	UPDATE Stage.LandRover_Portugal_Service
	SET ConvertedDeliveryDate = convert( datetime, STUFF(STUFF(DeliveryDate,3,0,'-'),6,0,'-'))
	WHERE isdate ( SUBSTRING( DeliveryDate, 1, 2) 
	             + '/' 
	             + SUBSTRING( DeliveryDate, 3, 2) 
	             + '/' 
	             + SUBSTRING( DeliveryDate, 5, 4) ) = 1
	AND LEN(DeliveryDate) = 8

	UPDATE Stage.LandRover_Portugal_Service
	SET ConvertedServiceDate = convert( datetime, STUFF(STUFF(ServiceDate,3,0,'-'),6,0,'-'))
	WHERE isdate ( SUBSTRING( ServiceDate, 1, 2) 
	             + '/' 
	             + SUBSTRING( ServiceDate, 3, 2) 
	             + '/' 
	             + SUBSTRING( ServiceDate, 5, 4) ) = 1
	AND LEN(ServiceDate) = 8
	
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
		INTO [$(ErrorDB)].Stage.LandRover_Portugal_Service_' + @TimestampString + '
		FROM Stage.LandRover_Portugal_Service
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH
