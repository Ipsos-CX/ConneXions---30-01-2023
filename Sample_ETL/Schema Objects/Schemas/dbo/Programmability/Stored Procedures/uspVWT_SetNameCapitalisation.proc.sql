CREATE PROCEDURE dbo.uspVWT_SetNameCapitalisation
AS

/*
	Purpose:	Sets the name data to have a leading capital and then all lower case for all records
				where the SetNameCapitalisation flag is set at load time
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspSTANDARDISE_ProperCaseName

*/


SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	UPDATE VWT
	SET
		VWT.Title = Lookup.udfGENERAL_GetCapitalisation(VWT.Title),
		VWT.FirstName  = Lookup.udfGENERAL_GetCapitalisation(VWT.FirstName),
		VWT.MiddleName = Lookup.udfGENERAL_GetCapitalisation(VWT.MiddleName),
		VWT.LastName = Lookup.udfGENERAL_GetCapitalisation(VWT.LastName),
		VWT.SecondLastName = Lookup.udfGENERAL_GetCapitalisation(VWT.SecondLastName)
	FROM dbo.VWT VWT
	WHERE VWT.SetNameCapitalisation = 1
	
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
