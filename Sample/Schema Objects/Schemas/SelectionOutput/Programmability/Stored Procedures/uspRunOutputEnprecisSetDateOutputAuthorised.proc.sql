


CREATE PROCEDURE SelectionOutput.uspRunOutputEnprecisSetDateOutputAuthorised
AS
SET NOCOUNT ON

/*
	Purpose:	Set Authorised Output date for all Enprecis selections that have just been outputted (i.e. currently in the output table.  
		
	Version			Date			Developer			Comment
	1.0				14/01/2014		Martin Riverol		Created

*/


DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY
	
	UPDATE SR
		SET DateOutputAuthorised = EO.OutputDate
	FROM SelectionOutput.ENPRECIS EO
	INNER JOIN Requirement.SelectionRequirements SR ON EO.SelectionRequirementID = SR.RequirementID
	
	
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


