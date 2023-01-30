
CREATE PROCEDURE Stage.uspStandardise_LandRover_Japan_Sales
AS

/*
	Purpose:	Convert the service date from a text string to a valid DATETIME type
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created from [Prophet-ETL].dbo.uspSTANDARDISE_STAGE_LandRover_Japan_Sales
	1.1				10-01-2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

SET LANGUAGE ENGLISH
SET DATEFORMAT YMD

BEGIN TRY

	UPDATE Stage.LandRover_Japan_Sales
	SET ConvertedRegistrationDate = CONVERT( DATETIME, STUFF(STUFF(RegistrationDate,3,0,'-'),6,0,'-' ))
	WHERE isdate ( SUBSTRING( RegistrationDate, 1, 2) 
	             + '/' 
	             + SUBSTRING( RegistrationDate, 3, 2) 
	             + '/' 
	             + SUBSTRING( RegistrationDate, 5, 2) ) = 1
	AND LEN(RegistrationDate) = 6
		--
	-- This is to stop loading data where the date conversion has errors
	--
	SELECT	CONVERT( DATETIME, STUFF(STUFF(RegistrationDate,3,0,'-'),6,0,'-' ))
    FROM    Stage.LandRover_Japan_Sales
	WHERE   ISDATE ( SUBSTRING( RegistrationDate, 1, 2) 
	               + '/' 
	               + SUBSTRING( RegistrationDate, 3, 2) 
	               + '/' 
	               + SUBSTRING( RegistrationDate, 5, 2) ) = 0
	AND LEN(RegistrationDate) = 6

	
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
		INTO [$(ErrorDB)].Stage.LandRover_Japan_Sales_' + @TimestampString + '
		FROM Stage.LandRover_Japan_Sales
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
END CATCH