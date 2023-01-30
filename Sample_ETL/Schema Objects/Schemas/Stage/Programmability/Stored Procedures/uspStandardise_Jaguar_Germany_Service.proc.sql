CREATE PROCEDURE Stage.uspStandardise_Jaguar_Germany_Service
AS
/*
	Purpose:	Convert the service date from a text string to a valid DATETIME type
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspSTANDARDISE_STAGE_Jaguar_Germany_Service

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

	UPDATE Stage.Jaguar_Germany_Service 
	SET ConvertedRegistrationDate = CONVERT( DATETIME, RegistrationDate )		
	WHERE ISDATE ( RegistrationDate ) = 1
	AND LEN(RegistrationDate) = 8

	UPDATE Stage.Jaguar_Germany_Service
	SET ConvertedRetailDate = convert( DATETIME, RetailDate )
	WHERE isdate (  RetailDate ) = 1
	AND LEN(RetailDate) = 8

	UPDATE Stage.Jaguar_Germany_Service
	SET ConvertedDeliveryDate = CONVERT( DATETIME, DeliveryDate )
	WHERE isdate ( DeliveryDate ) = 1
	AND LEN(DeliveryDate) = 8
	
	UPDATE Stage.Jaguar_Germany_Service
	SET ConvertedSalesDate = CONVERT( DATETIME, SalesDate )
	WHERE isdate ( SalesDate ) = 1
	AND LEN(SalesDate) = 8

	UPDATE Stage.Jaguar_Germany_Service
	SET ConvertedServiceEventDate = CONVERT( DATETIME, ServiceEventDate )
	WHERE isdate ( ServiceEventDate ) = 1
	AND LEN(ServiceEventDate) = 8
	
	/*
	--
	-- This to stop loading data where the date conversion has errors
	--
	SELECT	CONVERT( DATETIME, RegistrationDate )
	FROM	Stage.Jaguar_Germany_Service
	WHERE	ISDATE ( RegistrationDate ) = 0
	AND LEN(RegistrationDate) = 8

	SELECT	CONVERT( DATETIME, RetailDate )
	FROM	Stage.Jaguar_Germany_Service 
	WHERE	ISDATE ( RetailDate ) = 0
	AND LEN(RetailDate) = 8
	
	SELECT	CONVERT( DATETIME, DeliveryDate )
	FROM	Stage.Jaguar_Germany_Service 
	WHERE	ISDATE ( DeliveryDate ) = 0
	AND LEN(DeliveryDate) = 8

	SELECT	CONVERT( DATETIME, SalesDate )
	FROM	Stage.Jaguar_Germany_Service 
	WHERE	ISDATE ( SalesDate ) = 0
	AND LEN(SalesDate) = 8

	SELECT	CONVERT( DATETIME, ServiceEventDate )
	FROM	Stage.Jaguar_Germany_Service 
	WHERE	ISDATE ( ServiceEventDate ) = 0
	AND LEN(ServiceEventDate) = 8
	*/
	
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
		INTO [$(ErrorDB)].Stage.Jaguar_Germany_Service_' + @TimestampString + '
		FROM Stage.Jaguar_Germany_Service
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
	
END CATCH