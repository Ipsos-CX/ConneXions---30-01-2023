
CREATE PROCEDURE Stage.uspStandardise_LandRover_Korea_Sales
AS

/*
	Purpose:	Convert the SalesEvent date from a text to a valid DATETIME type
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Kamesh		

*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

SET LANGUAGE ENGLISH
SET DATEFORMAT MDY

BEGIN TRY

	UPDATE Stage.LandRover_Korea_Sales
	SET	ConvertedSalesEventDate = CAST(SalesEventDate AS DATETIME2)
	WHERE ISDATE(SalesEventDate) = 1
	AND		LEN(LTRIM(RTRIM(SalesEventDate))) = 10
	
		
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
		INTO [$(ErrorDB)].Stage.LandRover_Korea_Sales_' + @TimestampString + '
		FROM Stage.LandRover_Korea_Sales
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
END CATCH