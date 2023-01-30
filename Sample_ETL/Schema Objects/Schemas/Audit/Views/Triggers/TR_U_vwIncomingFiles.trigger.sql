



CREATE TRIGGER Audit.TR_U_vwIncomingFiles ON Audit.vwIncomingFiles
INSTEAD OF UPDATE
AS

/*
	Purpose:	Used to set the LoadSuccess and FileLoadFailureID values
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from trigger on [Prophet-ETL].dbo.vwAUDIT_SampleFiles

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

	UPDATE INF
	SET  INF.LoadSuccess = ISNULL(I.LoadSuccess, 0)
		,INF.FileLoadFailureID = I.FileLoadFailureID
	FROM [$(AuditDB)].dbo.IncomingFiles INF
	INNER JOIN INSERTED I ON I.AuditID = INF.AuditID

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


