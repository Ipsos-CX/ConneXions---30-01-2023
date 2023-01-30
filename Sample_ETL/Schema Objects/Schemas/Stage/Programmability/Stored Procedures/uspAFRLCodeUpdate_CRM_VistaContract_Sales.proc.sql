CREATE PROCEDURE [Stage].[uspAFRLCodeUpdate_CRM_VistaContract_Sales]
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
	-- Update the AFRL code (SalesTypeCode) in the CRM VISTA Contract Sales staging table
	----------------------------------------------------------------------------------------------------

	UPDATE s
	SET AFRLCode = ''
	from CRM.Vista_Contract_Sales s

	    
   UPDATE  C
    SET     AFRLCode = DetailedSalesTypeCode
    FROM    CRM.Vista_Contract_Sales C
    INNER JOIN Lookup.AFRLCodes L ON L.VIN = C.VEH_VIN
    WHERE C.DateTransferredToVWT IS NULL       ; 
                
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