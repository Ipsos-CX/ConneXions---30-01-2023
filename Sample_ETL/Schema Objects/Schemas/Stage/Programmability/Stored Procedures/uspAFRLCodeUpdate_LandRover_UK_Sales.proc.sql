CREATE PROCEDURE [Stage].[uspAFRLCodeUpdate_LandRover_UK_Sales]
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
	-- Update the AFRL code (SalesTypeCode) in the LandRover Sales staging table
	----------------------------------------------------------------------------------------------------

	UPDATE s
	SET AFRLCode = ''
	from [Stage].[LandRover_UK_Sales] s

	    
	;WITH CTE_VINs
	AS (
		SELECT WorldManufacturingID + Substring(VIN, 1, 8) + Substring(VIN, 11, 6) AS VIN_C, * 
		FROM   [Stage].LandRover_UK_Sales  C
	)
    UPDATE  C
    SET     [AFRLCode] = DetailedSalesTypeCode
	FROM    CTE_VINs  C
	JOIN Lookup.AFRLCodes L ON L.VIN = C.VIN_C;
            
                
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