CREATE PROC [SelectionOutput].[uspGetPostalBatch]
(
	@NumberInBatch INT
)
AS

/*
	Purpose:	Identifies a batch of postal records to output by setting the Outputted flag
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	DECLARE @SQL VARCHAR(500)
	
	SET @SQL = 'UPDATE SelectionOutput.Postal
				SET Outputted = 1
				WHERE ID IN (
					SELECT TOP ' + CAST(@NumberInBatch AS VARCHAR(20)) + ' ID
					FROM SelectionOutput.Postal
					ORDER BY ID
				)'
	
	EXEC (@SQL)
	
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
		
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END	
	
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH