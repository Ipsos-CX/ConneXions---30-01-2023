﻿CREATE PROCEDURE CustomerUpdate.uspOrganisation_Dedupe

AS

/*
	Purpose:	De-dupes the CaseID and PartyID pairs by setting the ParentAuditItemID column to be the maximum AuditItemID for each pair
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspIP_CUSTOMERUPDATE_Dedupe_Organisation

*/


SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	UPDATE P
	SET P.ParentAuditItemID = M.ParentAuditItemID
	FROM CustomerUpdate.Organisation P
	INNER JOIN (
		SELECT
			MAX(AuditItemID) AS ParentAuditItemID,
			PartyID,
			CaseID
		FROM CustomerUpdate.Organisation
		GROUP BY CaseID, PartyID
	) M ON M.CaseID = P.CaseID AND M.PartyID = P.PartyID

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

