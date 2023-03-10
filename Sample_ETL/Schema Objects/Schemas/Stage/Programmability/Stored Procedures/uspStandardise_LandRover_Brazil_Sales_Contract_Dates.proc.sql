CREATE PROCEDURE [Stage].[uspStandardise_LandRover_Brazil_Sales_Contract_Dates]

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

	UPDATE Stage.LandRover_Brazil_Sales_Contract
	SET ConvertedContractDate = CAST( ContractDate AS DATETIME2 )
	WHERE ISDATE(ContractDate) = 1

	UPDATE Stage.LandRover_Brazil_Sales_Contract
	SET ConvertedHandoverDate = CAST( HandoverDate AS DATETIME2 )
	WHERE ISDATE(HandoverDate) = 1

	UPDATE Stage.LandRover_Brazil_Sales_Contract
	SET ConvertedCancelDate = CAST( CancelDate AS DATETIME2 )
	WHERE ISDATE(CancelDate) = 1

	UPDATE Stage.LandRover_Brazil_Sales_Contract
	SET ConvertedDateCreated = CAST( DateCreated AS DATETIME2 )
	WHERE ISDATE(DateCreated) = 1

	UPDATE Stage.LandRover_Brazil_Sales_Contract
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
		INTO [$(ErrorDB)].Stage.LandRover_Brazil_Sales_Contract_' + @TimestampString + '
		FROM Stage.LandRover_Brazil_Sales_Contract
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
	
END CATCH

