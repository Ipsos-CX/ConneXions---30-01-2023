CREATE PROCEDURE Stage.uspStandardise_Jaguar_Australia_Service
AS

/*
	Purpose:	Convert the service date from a text string to a valid DATETIME type
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspSTANDARDISE_STAGE_Jaguar_Australia_AfterSales_Dates

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

	UPDATE	Stage.Jaguar_Australia_Service
	SET		ConvertedVehicleDeliveryDate = CONVERT( DATETIME, VehicleDeliveryDate )
	WHERE	isdate ( VehicleDeliveryDate ) = 1
	AND		LEN(VehicleDeliveryDate) >= 8

	UPDATE	Stage.Jaguar_Australia_Service
	SET		ConvertedVehicleRegistrationDate = convert( DATETIME, VehicleRegistrationDate )
	WHERE	ISDATE( VehicleRegistrationDate ) = 1
	AND		LEN( VehicleRegistrationDate ) >= 8
	
	UPDATE	Stage.Jaguar_Australia_Service
	SET		ConvertedServiceEventDate = CONVERT( DATETIME, ServiceEventDate )
	WHERE	ISDATE( ServiceEventDate ) = 1
	AND		LEN( ServiceEventDate ) >= 8
	
	UPDATE	Stage.Jaguar_Australia_Service
	SET		ConvertedVehiclePurchaseDate = CONVERT( DATETIME, VehiclePurchaseDate )
	WHERE	ISDATE( VehiclePurchaseDate ) = 1
	AND		LEN( VehiclePurchaseDate ) >= 8

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
		INTO [$(ErrorDB)].Stage.Jaguar_Australia_Service_' + @TimestampString + '
		FROM Stage.Jaguar_Australia_Service
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
		
END CATCH




