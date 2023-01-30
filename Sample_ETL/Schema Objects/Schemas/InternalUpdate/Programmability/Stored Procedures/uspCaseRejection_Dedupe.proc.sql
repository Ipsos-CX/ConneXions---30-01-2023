CREATE PROCEDURE [InternalUpdate].[uspCaseRejection_Dedupe]

AS
SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	UPDATE CR
	SET CR.ParentAuditItemID = M.ParentAuditItemID
	FROM InternalUpdate.CaseRejections CR
	INNER JOIN (
		SELECT
			MAX(AuditItemID) AS ParentAuditItemID,
			PartyID,
			CaseID
		FROM InternalUpdate.CaseRejections
		GROUP BY CaseID, PartyID
	) M ON M.CaseID = CR.CaseID AND M.PartyID = CR.PartyID


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
