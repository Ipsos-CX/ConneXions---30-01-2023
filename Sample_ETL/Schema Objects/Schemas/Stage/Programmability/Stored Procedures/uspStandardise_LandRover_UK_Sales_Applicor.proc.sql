CREATE PROCEDURE Stage.uspStandardise_LandRover_UK_Sales_Applicor
AS

/*
	Purpose:	Convert the sales dates from a text string to a valid DATETIME type
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspSTANDARDISE_STAGE_LandRover_UK_Sales_Dates

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

	UPDATE Stage.LandRover_UK_Sales_Applicor
	SET  ConvertedFirstRegistrationDate = FirstRegistrationDate
	WHERE ISDATE(FirstRegistrationDate) = 1
	
	UPDATE Stage.LandRover_UK_Sales_Applicor
	SET ConvertedHandoverDate = HandoverDate
	WHERE ISDATE(HandoverDate) = 1
	
	UPDATE Stage.LandRover_UK_Sales_Applicor
	SET ConvertedDateOfBirth = DateOfBirth
	WHERE ISDATE(DateOfBirth) = 1

	UPDATE Stage.LandRover_UK_Sales_Applicor
	SET ConvertedOwnershipStart = OwnershipStart
	WHERE ISDATE(OwnershipStart) = 1
	
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
		INTO [$(ErrorDB)].Stage.LandRover_UK_Sales_Applicor_' + @TimestampString + '
		FROM Stage.LandRover_UK_Sales_Applicor
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH
