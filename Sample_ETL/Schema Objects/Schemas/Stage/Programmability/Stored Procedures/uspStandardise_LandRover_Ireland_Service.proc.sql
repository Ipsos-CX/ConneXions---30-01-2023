CREATE PROCEDURE Stage.uspStandardise_LandRover_Ireland_Service
AS

/*
	Purpose:	Convert the service date from a text string to a valid DATETIME type
	
	Version		Date			Developer			Comment
	1.0			24/10/2013		Martin Riverol		Created

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

	UPDATE Stage.LandRover_Ireland_Service
	SET VehiclePurchaseDateConverted = VehiclePurchaseDate
	WHERE ISDATE(VehiclePurchaseDate) = 1
	AND LEN(VehiclePurchaseDate) = 10
	
	UPDATE Stage.LandRover_Ireland_Service
	SET VehicleRegistrationDateConverted = VehicleRegistrationDate
	WHERE ISDATE(VehicleRegistrationDate) = 1
	AND LEN(VehicleRegistrationDate) = 10
	
	UPDATE Stage.LandRover_Ireland_Service
	SET VehicleDeliveryDateConverted = VehicleDeliveryDate
	WHERE ISDATE(VehicleDeliveryDate) = 1
	AND LEN(VehicleDeliveryDate) = 10
	
	UPDATE Stage.LandRover_Ireland_Service
	SET ServiceEventDateConverted = ServiceEventDate
	WHERE ISDATE(ServiceEventDate) = 1
	AND LEN(ServiceEventDate) = 10
	
	
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
		INTO [$(ErrorDB)].Stage.LandRover_Ireland_Service_' + @TimestampString + '
		FROM Stage.LandRover_Ireland_Service
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
END CATCH