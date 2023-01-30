
CREATE PROCEDURE Stage.uspStandardise_Jaguar_Germany_Sales
AS
/*
	Purpose:	Convert the service date from a text string to a valid DATETIME type
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspSTANDARDISE_STAGE_Jaguar_Germany_Sales

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

	UPDATE Stage.Jaguar_Germany_Sales 
	SET ConvertedCreateDate = CONVERT( DATETIME, CreateDate )		
	WHERE ISDATE ( CreateDate ) = 1
	AND LEN(CreateDate) = 10

	UPDATE Stage.Jaguar_Germany_Sales
	SET ConvertedRegDate = convert( DATETIME, RegDate )
	WHERE isdate (  RegDate ) = 1
	AND LEN(RegDate) = 10

	UPDATE Stage.Jaguar_Germany_Sales
	SET ConvertedDeliveryDate = CONVERT( DATETIME, DeliveryDate )
	WHERE isdate ( DeliveryDate ) = 1
	AND LEN(DeliveryDate) = 10
	--
	-- This to stop loading data where the date conversion has errors
	--
	SELECT	CONVERT( DATETIME, CreateDate )
	FROM	Stage.Jaguar_Germany_Sales
	WHERE	ISDATE ( CreateDate ) = 0
	AND LEN(CreateDate) = 10

	SELECT	CONVERT( DATETIME, RegDate )
	FROM	Stage.Jaguar_Germany_Sales 
	WHERE	ISDATE ( RegDate ) = 0
	AND LEN(RegDate) = 10
	
	SELECT	CONVERT( DATETIME, DeliveryDate )
	FROM	Stage.Jaguar_Germany_Sales 
	WHERE	ISDATE ( DeliveryDate ) = 0
	AND LEN(DeliveryDate) = 10
	
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
		INTO [$(ErrorDB)].Stage.Jaguar_Germany_Sales_' + @TimestampString + '
		FROM Stage.Jaguar_Germany_Sales
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
	
END CATCH