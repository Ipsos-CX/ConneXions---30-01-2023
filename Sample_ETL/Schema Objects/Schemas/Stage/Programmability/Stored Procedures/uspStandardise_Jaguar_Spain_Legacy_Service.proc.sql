CREATE PROCEDURE Stage.uspStandardise_Jaguar_Spain_Legacy_Service 
AS

/*
	Purpose:	Convert the supplied dates from a text string to a valid DATETIME type
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	E Thomas			Copied from Stage.uspStandardise_Jaguar_Spain_Service (dated 6/03/12 18:21)

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

	UPDATE Stage.Jaguar_Spain_Legacy_Service
	SET ConvertedPurchaseDate = convert( datetime, STUFF(STUFF(PurchaseDate,3,0,'-'),6,0,'-'))
	WHERE isdate ( SUBSTRING( PurchaseDate, 1, 2) 
	             + '/' 
	             + SUBSTRING( PurchaseDate, 3, 2) 
	             + '/' 
	             + SUBSTRING( PurchaseDate, 5, 4) ) = 1
	AND LEN(PurchaseDate) = 8

	UPDATE Stage.Jaguar_Spain_Legacy_Service
	SET ConvertedRegDate = convert( datetime, STUFF(STUFF(RegDate,3,0,'-'),6,0,'-'))
	WHERE isdate ( SUBSTRING( RegDate, 1, 2) 
	             + '/' 
	             + SUBSTRING( RegDate, 3, 2) 
	             + '/' 
	             + SUBSTRING( RegDate, 5, 4) ) = 1
	AND LEN(RegDate) = 8

	UPDATE Stage.Jaguar_Spain_Legacy_Service
	SET ConvertedDeliveryDate = convert( datetime, STUFF(STUFF(DeliveryDate,3,0,'-'),6,0,'-'))
	WHERE isdate ( SUBSTRING( DeliveryDate, 1, 2) 
	             + '/' 
	             + SUBSTRING( DeliveryDate, 3, 2) 
	             + '/' 
	             + SUBSTRING( DeliveryDate, 5, 4) ) = 1
	AND LEN(DeliveryDate) = 8

	UPDATE Stage.Jaguar_Spain_Legacy_Service
	SET ConvertedServiceEventDate = convert( datetime, STUFF(STUFF(ServiceEventDate,3,0,'-'),6,0,'-'))
	WHERE isdate ( SUBSTRING( ServiceEventDate, 1, 2) 
	             + '/' 
	             + SUBSTRING( ServiceEventDate, 3, 2) 
	             + '/' 
	             + SUBSTRING( ServiceEventDate, 5, 4) ) = 1
	AND LEN(ServiceEventDate) = 8
	
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
		INTO [$(ErrorDB)].Stage.Jaguar_Spain_Legacy_Service_' + @TimestampString + '
		FROM Stage.Jaguar_Spain_Legacy_Service
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH

