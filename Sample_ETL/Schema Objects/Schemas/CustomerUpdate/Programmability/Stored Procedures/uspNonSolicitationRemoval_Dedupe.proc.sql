CREATE PROCEDURE CustomerUpdate.uspNonSolicitationRemoval_Dedupe

AS

/*
	Purpose:	De-dupes the CaseID and PartyID pairs by setting the ParentAuditItemID column to be the maximum AuditItemID for each pair
	
	Version			Date			Developer			Comment
	1.0				$20/05/2014		Ali Yuksel		
	
*/


SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	UPDATE CO
	SET CO.ParentAuditItemID = M.ParentAuditItemID
	FROM CustomerUpdate.NonSolicitationRemoval CO
	INNER JOIN (
		SELECT
			MAX(AuditItemID) AS ParentAuditItemID,
			FullName,
			VIN,
			EventDateOrig
		FROM CustomerUpdate.NonSolicitationRemoval
		GROUP BY FullName, VIN, EventDateOrig
	) M ON M.FullName = CO.FullName AND M.VIN = CO.VIN  AND M.EventDateOrig = CO.EventDateOrig


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




