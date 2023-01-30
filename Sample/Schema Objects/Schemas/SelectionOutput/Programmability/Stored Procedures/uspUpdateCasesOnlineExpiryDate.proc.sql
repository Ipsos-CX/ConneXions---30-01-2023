
/*

CREATE PROCEDURE SelectionOutput.uspUpdateCasesOnlineExpiryDate
AS
SET NOCOUNT ON


-->>>>>>>>>>> NO LONGER USED -> FOR DELETION <<<<<<<<<<<<<<<<<<

-- CGR 12/02/2013 - This proc has been replaced by SelectionOutput.uspUpdateCasesFromOutput


--------------------------------------------------------------------------------------------
--
-- Name : SelectionOutput.uspUpdateCasesOnlineExpiryDate
--
-- Desc : Update the On-line Expiry Dates on Cases table 
--
-- Change History...
-- 
-- Version	Date		Author		Description
-- =======	====		======		===========
--	1.0		19-03-2012	Chris Ross	Original version
--
--------------------------------------------------------------------------------------------


DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY
	
	UPDATE C
	SET OnlineExpirydate = OO.Expired 
	FROM SelectionOutput.OnlineOutput OO 
	INNER JOIN Event.Cases C ON C.CaseID = OO.ID 
	WHERE OO.Expired IS NOT NULL
	AND OO.ITYPE = 'H' -- on-line
	AND C.OnlineExpirydate IS NULL
	
END TRY
BEGIN CATCH

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [Sample_Errors].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH


*/