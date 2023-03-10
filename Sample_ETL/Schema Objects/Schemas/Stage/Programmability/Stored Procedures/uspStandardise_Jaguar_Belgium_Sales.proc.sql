CREATE PROCEDURE Stage.uspStandardise_Jaguar_Belgium_Sales
AS

/*
	Purpose:	Convert the service date from a text string to a valid DATETIME type
	
	Version			Date			Developer			Comment
	1.0				06-11-2014		Chris Ross			Created from Stage.uspStandardise_LandRover_Belgium_Sales

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

	UPDATE Stage.Jaguar_Belgium_Sales
	SET ConvertedRegistrationDate = CAST(RegistrationDate AS DATETIME2)
	WHERE ISDATE(RegistrationDate) = 1

	UPDATE Stage.Jaguar_Belgium_Sales
	SET ConvertedSalesEventDate = CAST(RetailDate AS DATETIME2)
	WHERE ISDATE(RetailDate) = 1

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
		INTO [$(ErrorDB)].Stage.LandRover_Belgium_Sales_' + @TimestampString + '
		FROM Stage.LandRover_Belgium_Sales
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
END CATCH