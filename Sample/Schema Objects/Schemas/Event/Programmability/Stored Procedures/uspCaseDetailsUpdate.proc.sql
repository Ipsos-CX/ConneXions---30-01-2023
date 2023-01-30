
CREATE PROCEDURE [Event].[uspCasesDetailsUpdate]
AS
SET NOCOUNT ON

--------------------------------------------------------------------------------------------
--
-- Name : [Event].[uspCasesDetailsUpdate]
--
-- Desc : Updates Event.Case details using Warehouse.IR_CaseDetails table.
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

	UPDATE E
	SET ClosureDate = cd.ClosureDate
	FROM Event.Cases E
	INNER JOIN Warehouse.IR_CaseDetails cd on E.CaseID = cd.CaseID 


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

