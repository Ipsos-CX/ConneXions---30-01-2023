
CREATE PROCEDURE OWAPv2.uspGDPRReturnOriginatingDataRows

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
	Purpose:	Returns the originating files and rows from a GDPR "Right to Erasure" request.
		
	Version			Date			Developer			Comment
	1.0				16-04-2018		Chris Ross			BUG 14399 - Original version.
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
	-- Output originating data row information 
	------------------------------------------------------------------------

	SELECT	er.PartyID, 
			er.RequestDate,
			er.FullErasure, 
			er.RequestedBy,
			odr.FileType,
			odr.ActionDate AS FileLoadedDate,
			Filename, 
			odr.PhysicalRow
	FROM [$(AuditDB)].GDPR.ErasureRequests er
	LEFT JOIN [$(AuditDB)].dbo.AuditItems ai 
			INNER JOIN [$(AuditDB)].GDPR.OriginatingDataRows odr ON odr.AuditItemID = ai.AuditItemID
		ON ai.AuditID = er.AuditID
	WHERE er.PartyID = @PartyID
	ORDER BY er.RequestDate, odr.FileType, odr.ActionDate


	RETURN 1

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

