CREATE PROCEDURE [OWAPv2].[uspReIssueInvite]
@CaseID [dbo].[CaseID], @PartyID [dbo].[PartyID], @SessionID [dbo].[SessionID]=N'', @AuditID [dbo].[AuditID]=0, @UserPartyID [dbo].[PartyID]=0, @ErrorCode INT=0 OUTPUT, @InviteReIssued BIT=0 OUTPUT
AS

/*
	Purpose:	OWAP Reissue Invite SP

	Version		Date			Developer			Comment
	1.1			2017-03-02		Chris Ledger		Fix Bug whereby CaseID and PartyID wrong way round
	1.2			2017-03-09		Chris Ledger		BUG 13543 - Fix Bug whereby Reissue Set to INT instead of BIT
	1.3			2020-01-21		Chris Ledger		BUG 15372: Fix Hard coded references to databases.	
*/

SET NOCOUNT, XACT_ABORT ON;

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

		DECLARE @AuditItemID dbo.AuditItemID
		DECLARE @ActionDate DATETIME2
		DECLARE @UserRoleTypeID [dbo].RoleTypeID
		DECLARE @UserPartyRoleID [dbo].PartyRoleID 
				
		SET @ActionDate = GETDATE()

		---------------------------------------------------------------------------
		-- GET THE USER DETAILS
		---------------------------------------------------------------------------
		IF (ISNULL( @UserPartyID, 0 ) = 0 )
		BEGIN
			SELECT 
				@UserPartyID = U.PartyID,
				@UserRoleTypeID = U.RoleTypeID,
				@UserPartyRoleID = U.PartyRoleID
			FROM
				OWAP.vwUsers U
			WHERE
				U.UserName = 'OWAPAdmin'
		END
		ELSE
		BEGIN
			SELECT 
				@UserRoleTypeID = U.RoleTypeID,
				@UserPartyRoleID = U.PartyRoleID
			FROM
				OWAP.vwUsers U
			WHERE
				U.PartyID = @UserPartyID
		END
		
		IF (ISNULL( @AuditID, 0 ) = 0 )
		BEGIN
			EXECUTE	[OWAP].[uspAuditSession] 'OWAP Reissue Invite', @userPartyRoleID, @AuditID Output, @ErrorCode Output
		END

		---------------------------------------------------------------------------
		-- AUDIT THE ACTION AND GET THE RESULTANT AuditItemID
		---------------------------------------------------------------------------
		EXEC [OWAP].[uspAuditAction] @AuditID, @ActionDate, @UserPartyID, @UserRoleTypeID, @AuditItemID OUTPUT, @ErrorCode OUTPUT
	
	
	
		---------------------------------------------------------------------------
		-- VALIDATE INSERTED RECORDS
		---------------------------------------------------------------------------

		CREATE TABLE #ReIssueInvite

			(
				CaseID INT,
				PartyID INT,
				ReIssue BIT,
				CasePartyCombinationValid BIT				
			)
		
		
		INSERT INTO #ReIssueInvite

			(
				CaseID,
				PartyID,
				ReIssue,
				CasePartyCombinationValid
			)

				SELECT DISTINCT
					 @CaseID,
					 @PartyID,
					 1,
					 0
		
		---------------------------------------------------------------------------
		-- CHECK THE CaseID AND PartyID
		---------------------------------------------------------------------------

		UPDATE #ReIssueInvite
		SET CasePartyCombinationValid = 1
		FROM #ReIssueInvite RI
		INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = RI.CaseID AND AEBI.PartyID = RI.PartyID


		----------------------------------------------------------------------
		--- CHECK WHETHER INVALID LOAD REASONS and FAIL AND RETURN, IF THERE ARE  
		----------------------------------------------------------------------

		SELECT @InviteReIssued = CasePartyCombinationValid
		FROM #ReIssueInvite 

		IF @InviteReIssued = 0
		BEGIN
			RETURN 0   -- Exit
		END

		------------------------------------------------------------------------
		------------------------------------------------------------------------
		------------------------------------------------------------------------

	BEGIN TRAN

		---------------------------------------------------------------------------
		-- SAVE OUTPUT
		---------------------------------------------------------------------------
		INSERT INTO [OWAPv2].[ReIssueInvite]
			(
				CaseID,
				PartyID, 
				ReIssue, 
				AuditID, 
				AuditItemID, 
				CasePartyCombinationValid
			)
				SELECT @CaseID,
					@PartyID,
					1,
					@AuditID,
					@AuditItemID,
					1
		---------------------------------------------------------------------------
		
		
		---------------------------------------------------------------------------
		-- RUN JOB TO CREATE REISSUE INVITE FILE
		---------------------------------------------------------------------------
		EXEC msdb.dbo.sp_start_job 'Internal Updates: Create ReIssue Invite File'
		---------------------------------------------------------------------------
				
	COMMIT TRAN
	
END TRY
BEGIN CATCH

	ROLLBACK

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