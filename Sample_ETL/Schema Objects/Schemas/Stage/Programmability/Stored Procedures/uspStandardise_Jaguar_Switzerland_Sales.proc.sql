

CREATE PROCEDURE Stage.uspStandardise_Jaguar_Switzerland_Sales
AS

/*
	Purpose:	Convert the service date from a text string to a valid DATETIME type
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspSTANDARDISE_STAGE_Jaguar_Switzerland_Sales

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

	UPDATE	Stage.Jaguar_Switzerland_Sales
	SET		ConvertedDeliveryDate = CONVERT( DATETIME, LTRIM(RTRIM((DeliveryDate))))
	WHERE	ISDATE ( LTRIM(RTRIM(DeliveryDate ))) = 1
	AND		LEN(LTRIM(RTRIM(DeliveryDate))) = 10
	--
	-- This is to stop loading data where the date conversion has errors
	--
	SELECT	CONVERT( DATETIME, LTRIM(RTRIM(DeliveryDate )))
    FROM    Stage.Jaguar_Switzerland_Sales
	WHERE   ISDATE ( LTRIM(RTRIM(DeliveryDate ))) = 0
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
		INTO [$(ErrorDB)].Stage.Jaguar_Switzerland_Sales_' + @TimestampString + '
		FROM Stage.Jaguar_Switzerland_Sales
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
END CATCH