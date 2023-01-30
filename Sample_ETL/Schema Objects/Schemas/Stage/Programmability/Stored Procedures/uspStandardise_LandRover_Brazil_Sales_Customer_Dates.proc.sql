CREATE PROCEDURE [Stage].[uspStandardise_LandRover_Brazil_Sales_Customer_Dates]

AS
DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

SET LANGUAGE ENGLISH
SET DATEFORMAT YMD

BEGIN TRY

	UPDATE Stage.LandRover_Brazil_Sales_Customer
	SET ConvertedDateOfBirth = CAST( DateOfBirth AS DATETIME2 )
	WHERE ISDATE(DateOfBirth) = 1

	UPDATE Stage.LandRover_Brazil_Sales_Customer
	SET ConvertedTelephoneOptInDate = CAST( TelephoneOptInDate AS DATETIME2 )
	WHERE ISDATE(TelephoneOptInDate) = 1

	UPDATE Stage.LandRover_Brazil_Sales_Customer
	SET ConvertedEmailOptInDate = CAST( EmailOptInDate AS DATETIME2 )
	WHERE ISDATE(EmailOptInDate) = 1

	UPDATE Stage.LandRover_Brazil_Sales_Customer
	SET ConvertedMobileOptInDate = CAST( MobileOptInDate AS DATETIME2 )
	WHERE ISDATE(MobileOptInDate) = 1

	UPDATE Stage.LandRover_Brazil_Sales_Customer
	SET ConvertedDateCreated = CAST( DateCreated AS DATETIME2 )
	WHERE ISDATE(DateCreated) = 1

	UPDATE Stage.LandRover_Brazil_Sales_Customer
	SET ConvertedLastUpdated = CAST( LastUpdated AS DATETIME2 )
	WHERE ISDATE(LastUpdated) = 1
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
		INTO [$(ErrorDB)].Stage.LandRover_Brazil_Sales_Customer_' + @TimestampString + '
		FROM Stage.LandRover_Brazil_Sales_Customer
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
	
END CATCH

