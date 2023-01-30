CREATE PROCEDURE [Stage].[uspStandardise_LandRover_China_Sales]
AS
/*
	Purpose:	Standardise the delivery date and populate the salesdate
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created
	1.1				31-May-2012		Pardip Mudhar		BUG 7005: It was giving runtime error during date converion this has been updated so loads the good data.
	1.2				10-01-2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
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

	UPDATE Stage.LandRover_China_Sales 
	SET ConvertedSalesDate = CONVERT(DATETIME, DeliveryDate, 112 )
	WHERE ISDATE(DeliveryDate) = 1 AND LEN(LTRIM(RTRIM(DeliveryDate))) = 8


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
		INTO [$(ErrorDB)].Stage.LandRover_China_Sales_' + @TimestampString + '
		FROM Stage.LandRover_China_Sales
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
	
END CATCH