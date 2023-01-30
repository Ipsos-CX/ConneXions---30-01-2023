CREATE PROCEDURE [Stage].[uspAFRLCodeUpdate_Jaguar_Cupid_Sales]
AS
DECLARE @ErrorNumber			INT

DECLARE @ErrorSeverity			INT
DECLARE @ErrorState				INT
DECLARE @ErrorLocation			NVARCHAR(500)
DECLARE @ErrorLine				INT
DECLARE @ErrorMessage			NVARCHAR(2048)



SET LANGUAGE ENGLISH
BEGIN TRY


	----------------------------------------------------------------------------------------------------
	-- Update the AFRL code (SalesTypeCode) in the Jaguar Cupid staging table
	----------------------------------------------------------------------------------------------------
	
	UPDATE s
	SET AFRLCode = ''
	from [Stage].[Jaguar_Cupid_Sales] s

	    
    UPDATE  C
    SET     AFRLCode = DetailedSalesTypeCode
    FROM    [Stage].[Jaguar_Cupid_Sales] C
            JOIN Lookup.AFRLCodes L ON L.VIN = C.VIN;
            
                
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
			
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
	
END CATCH