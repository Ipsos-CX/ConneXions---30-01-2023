CREATE PROCEDURE CustomerUpdate.uspCRCAgentLookUp_Dedupe

AS

/*
	Purpose:	De-dupes the Agent Lookup table by setting the ParentAuditItemID column to be the maximum AuditItemID for each pair of CDSID And Market
	
	Version			Date				Developer			Comment
	1.0				$(ReleaseDate)		Eddie Thomas		Created from CustomerUpdate.uspPerson_Dedupe
	1.1				25/03/2021			Eddie Thomas		Auditing now occurs against table Stage.CRCAgents_GlobalList
	1.2				09/06/2021			Eddie Thomas		De-dupping now using Fullname
*/


SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

		UPDATE lk
	SET lk.ParentAuditItemID = M.ParentAuditItemID
	FROM Stage.CRCAgents_GlobalList lk
	INNER JOIN (
		SELECT
			MAX(AuditItemID) AS ParentAuditItemID,
				CDSID,MarketCode,FullName
		FROM	Stage.CRCAgents_GlobalList
		GROUP BY cdsid,MarketCode, FullName
	) M ON	M.[CDSID] = lk.CDSID AND	
			M.MarketCode = lk.MarketCode AND
			M.FullName  = lk.FullName
			
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


