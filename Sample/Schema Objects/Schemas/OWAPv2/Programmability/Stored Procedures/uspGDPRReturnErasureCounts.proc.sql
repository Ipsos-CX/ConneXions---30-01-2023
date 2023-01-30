CREATE PROCEDURE OWAPv2.uspGDPRReturnErasureCounts

	@PartyID					BIGINT, 
	@Validated					BIT OUTPUT,  
	@ValidationFailureReason	VARCHAR(255) OUTPUT
	
AS
SET NOCOUNT ON


DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

/*
	Purpose:	Returns the GDPR "Right of Erasure" record update counts for the partyID supplied.
			
	Version			Date			Developer			Comment
	1.0				09-05-2018		Chris Ross			BUG 14399 - Original version.
	1.1				21-01-2020		Chris Ledger		BUG 15372: Fix Hard coded references to databases.
*/


	------------------------------------------------------------------------
	-- Check params populated correctly
	------------------------------------------------------------------------

	SET @Validated = 0
	
		
	IF	@PartyID		IS NULL
	BEGIN
		SET @ValidationFailureReason = '@PartyID parameter has not been supplied'
		RETURN 0
	END 

	IF 0 = (SELECT COUNT(*) FROM [$(AuditDB)].GDPR.ErasureRequests WHERE PartyID = @PartyID)
	BEGIN
		SET @ValidationFailureReason = 'There are no erasure requests for this PartyID'
		RETURN 0
	END 
	
	
	SET @Validated = 1
	
	

	------------------------------------------------------------------------
	-- Return the erasure request counts
	------------------------------------------------------------------------

	SELECT	er.PartyID,
			er.FullErasure, 
			er.RequestDate,
			er.RequestedBy,
			erc.TableName,
			erc.UpdateType,
			erc.RecordCount
	FROM [$(AuditDB)].GDPR.ErasureRequests er
	LEFT JOIN [$(AuditDB)].dbo.AuditItems ai 
			INNER JOIN [$(AuditDB)].GDPR.ErasedRecordCounts erc ON erc.AuditItemID = ai.AuditItemID
		ON ai.AuditID = er.AuditID
	WHERE er.PartyID = @PartyID
	ORDER BY er.FullErasure, erc.TableName, erc.UpdateType


	RETURN 1


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

