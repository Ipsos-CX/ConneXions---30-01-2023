CREATE PROCEDURE [Stage].[uspAFRLCodeUpdate_CRM_PreOwned]
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
	-- Update the AFRL code (SalesTypeCode) in the CRM PreOwned staging table
	----------------------------------------------------------------------------------------------------

	UPDATE PO
	SET PO.AFRLCode = ''
	from CRM.PreOwned PO

	    
	UPDATE  PO
    SET     PO.AFRLCode = L.DetailedSalesTypeCode
    FROM    CRM.PreOwned PO
    INNER JOIN Lookup.AFRLCodes L ON L.VIN = PO.VEH_VIN
    WHERE PO.DateTransferredToVWT IS NULL; 
    
    
                
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