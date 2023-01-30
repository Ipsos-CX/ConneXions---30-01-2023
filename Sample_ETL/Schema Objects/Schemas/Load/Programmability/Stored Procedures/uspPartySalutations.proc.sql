CREATE PROCEDURE [Load].[uspPartySalutations]
AS

/*
	Purpose:	Loads any new salutations to the sample database 
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Ali Yuksel			Created

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN

		INSERT INTO [$(SampleDB)].Party.vwDA_PartySalutations
		(
			AuditItemID,
			PartyID, 
			Salutation
		)
		SELECT 
			AuditItemID, 
			PartyID,
			Salutation
		FROM Load.vwPartySalutations
		WHERE ISNULL(RTRIM(LTRIM(Salutation)),N'')<>''

		
	COMMIT TRAN
	
END TRY
BEGIN CATCH

	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END

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
