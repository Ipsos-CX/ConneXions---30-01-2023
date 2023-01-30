
CREATE PROCEDURE Stage.uspStandardise_LandRover_Italy_Sales
AS

/*
	Purpose:	Convert the service date from a text string to a valid DATETIME type
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspSTANDARDISE_STAGE_LandRover_Italy_Sales

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

	UPDATE Stage.LandRover_Italy_Sales
	SET ConvertedSalesDate = CONVERT( DATETIME, STUFF(STUFF(SalesDate,3,0,'-'),6,0,'-' ))
	WHERE isdate ( SUBSTRING( SalesDate, 1, 2) 
	             + '/' 
	             + SUBSTRING( SalesDate, 3, 2) 
	             + '/' 
	             + SUBSTRING( SalesDate, 5, 2) ) = 1
	AND LEN(SalesDate) = 6
		--
	-- This is to stop loading data where the date conversion has errors
	--
	SELECT	CONVERT( DATETIME, STUFF(STUFF(SalesDate,3,0,'-'),6,0,'-' ))
    FROM    Stage.LandRover_Italy_Sales
	WHERE   ISDATE ( SUBSTRING( SalesDate, 1, 2) 
	               + '/' 
	               + SUBSTRING( SalesDate, 3, 2) 
	               + '/' 
	               + SUBSTRING( SalesDate, 5, 2) ) = 0
	AND LEN(SalesDate) = 6

	
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
		INTO [$(ErrorDB)].Stage.LandRover_Italy_Sales_' + @TimestampString + '
		FROM Stage.LandRover_Italy_Sales
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
END CATCH