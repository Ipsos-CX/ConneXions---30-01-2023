CREATE PROCEDURE CustomerUpdate.uspSMSBouncebacks_Dedupe

AS

/*
	Purpose:	De-dupes the CaseID and PartyID pairs by setting the ParentAuditItemID column to be the maximum AuditItemID for each pair
	
	Version			Date			Developer			Comment
	1.0				20/01/2013		Chris Ross			Created.

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
	FROM CustomerUpdate.SMSBouncebacks CO
	INNER JOIN (
		SELECT
			MAX(AuditItemID) AS ParentAuditItemID,
			PartyID,
			CaseID,
			MobileNumber
		FROM CustomerUpdate.SMSBouncebacks 
		GROUP BY CaseID, PartyID, MobileNumber
	) M ON M.CaseID = CO.CaseID AND M.PartyID = CO.PartyID AND M.MobileNumber = CO.MobileNumber 


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




