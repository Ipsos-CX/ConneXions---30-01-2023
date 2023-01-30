CREATE PROCEDURE CaseUpdate.uspCRMLostLeadResponses_Dedupe

AS

/*
		Purpose:	De-dupes the unique records (i.e. [Event ID]) by setting the ParentAuditItemID column to be the maximum AuditItemID for each pair
	
		Version		Date				Developer			Comment
LIVE	1.0			2021-12-01			Chris Ledger		Created
*/

SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	UPDATE LLR
	SET LLR.ParentAuditItemID = M.ParentAuditItemID
	FROM CaseUpdate.CRMLostLeadResponses LLR
		INNER JOIN (	SELECT MAX(AuditItemID) AS ParentAuditItemID,
							LLR.[Case ID]
						FROM CaseUpdate.CRMLostLeadResponses LLR
						GROUP BY LLR.[Case ID]) M ON M.[Case ID] = LLR.[Case ID]
				
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