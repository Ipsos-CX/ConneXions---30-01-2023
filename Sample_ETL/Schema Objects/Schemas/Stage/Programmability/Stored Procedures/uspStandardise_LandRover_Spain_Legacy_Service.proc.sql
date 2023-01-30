CREATE PROCEDURE Stage.uspStandardise_LandRover_Spain_Legacy_Service 
AS

/*
	Purpose:	Convert the supplied dates from a text string to a valid DATETIME type
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	E Thomas			Copied from original uspStandardise_LandRover_Spain_Service (Dated 6/03/12 18:21) 
AS

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

	UPDATE Stage.LandRover_Spain_Legacy_Service
	SET ConvertedPurchaseDate = LEFT(REPLICATE('0', 8-LEN(PurchaseDate)) + PurchaseDate, 2) + '/' + 
		SUBSTRING(REPLICATE('0', 8-LEN(PurchaseDate)) + PurchaseDate, 3, 2) + '/' + 
		RIGHT(REPLICATE('0', 8-LEN(PurchaseDate)) + PurchaseDate, 2)
	WHERE ISDATE(LEFT(REPLICATE('0', 8-LEN(PurchaseDate)) + PurchaseDate, 2) + '/' + 
		SUBSTRING(REPLICATE('0', 8-LEN(PurchaseDate)) + PurchaseDate, 3, 2) + '/' + 
		RIGHT(REPLICATE('0', 8-LEN(PurchaseDate)) + PurchaseDate, 2)) = 1

	UPDATE Stage.LandRover_Spain_Legacy_Service
	SET ConvertedRegDate = LEFT(REPLICATE('0', 8-LEN(RegDate)) + RegDate, 2) + '/' + 
		SUBSTRING(REPLICATE('0', 8-LEN(RegDate)) + RegDate, 3, 2) + '/' + 
		RIGHT(REPLICATE('0', 8-LEN(RegDate)) + RegDate, 2)
	WHERE ISDATE(LEFT(REPLICATE('0', 8-LEN(RegDate)) + RegDate, 2) + '/' + 
		SUBSTRING(REPLICATE('0', 8-LEN(RegDate)) + RegDate, 3, 2) + '/' + 
		RIGHT(REPLICATE('0', 8-LEN(RegDate)) + RegDate, 2)) = 1

	UPDATE Stage.LandRover_Spain_Legacy_Service
	SET ConvertedDeliveryDate = LEFT(REPLICATE('0', 8-LEN(DeliveryDate)) + DeliveryDate, 2) + '/' + 
		SUBSTRING(REPLICATE('0', 8-LEN(DeliveryDate)) + DeliveryDate, 3, 2) + '/' + 
		RIGHT(REPLICATE('0', 8-LEN(DeliveryDate)) + DeliveryDate, 2)
	WHERE ISDATE(LEFT(REPLICATE('0', 8-LEN(DeliveryDate)) + DeliveryDate, 2) + '/' + 
		SUBSTRING(REPLICATE('0', 8-LEN(DeliveryDate)) + DeliveryDate, 3, 2) + '/' + 
		RIGHT(REPLICATE('0', 8-LEN(DeliveryDate)) + DeliveryDate, 2)) = 1

	UPDATE Stage.LandRover_Spain_Legacy_Service
	SET ConvertedServiceEventDate = LEFT(REPLICATE('0', 8-LEN(ServiceEventDate)) + ServiceEventDate, 2) + '/' + 
		SUBSTRING(REPLICATE('0', 8-LEN(ServiceEventDate)) + ServiceEventDate, 3, 2) + '/' + 
		RIGHT(REPLICATE('0', 8-LEN(ServiceEventDate)) + ServiceEventDate, 2)
	WHERE ISDATE(LEFT(REPLICATE('0', 8-LEN(ServiceEventDate)) + ServiceEventDate, 2) + '/' + 
		SUBSTRING(REPLICATE('0', 8-LEN(ServiceEventDate)) + ServiceEventDate, 3, 2) + '/' + 
		RIGHT(REPLICATE('0', 8-LEN(ServiceEventDate)) + ServiceEventDate, 2)) = 1

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
		INTO [$(ErrorDB)].Stage.LandRover_Spain_Legacy_Service_' + @TimestampString + '
		FROM Stage.LandRover_Spain_Legacy_Service
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH