CREATE PROC [OWAP].[uspSetCaseRejection]
(
		@CaseID dbo.CaseID,
		@Rejection BIT = 0,
		@SelectionID dbo.RequirementID, 
		@SessionID dbo.SessionID = N'',
		@AuditID dbo.AuditID = 0,
		@UserPartyID dbo.PartyID = 0,
		@ErrorCode INT = 0 OUTPUT
)

AS

/*
	Purpose:	Set a case to be rejected or remove the rejection
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created
	1.1				18-05-2012		Pardip Mudhar		Modified for OWAP Connexion
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
	
		DECLARE @AuditItemID dbo.AuditItemID
		DECLARE @ActionDate DATETIME2
		DECLARE @UserRoleTypeID [dbo].RoleTypeID
		DECLARE @UserPartyRoleID [dbo].PartyRoleID 
				
		SET @ActionDate = GETDATE()
		--
		-- When manual setting case rejection generate autdit id
		--
		--
		-- GET THE USER DETAILS
		--
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
			EXECUTE	[OWAP].[uspAuditSession] 'Manual Set Case Rejection', @userPartyRoleID, @AuditID Output, @ErrorCode Output
		END
		--
		-- AUDIT THE ACTION AND GET THE RESULTANT AuditItemID
		--
		EXEC OWAP.uspAuditAction @AuditID, @ActionDate, @UserPartyID, @UserRoleTypeID, @AuditItemID OUTPUT, @ErrorCode OUTPUT
		--
		-- ADD THE CASE REJECTION
		--
		INSERT INTO Event.vwDA_CaseRejections
		(
			AuditItemID,
			CaseID,
			Rejection,
			FromDate
		)
		SELECT
			@AuditItemID,
			@CaseID,
			@Rejection,
			@ActionDate
		
		-- SET THE REJECT COUNT
		IF @Rejection = 1
		BEGIN
			UPDATE Requirement.SelectionRequirements
			SET RecordsRejected = ISNULL(RecordsRejected, 0) + 1
			WHERE RequirementID = @SelectionID
			
			UPDATE	CD
			SET		 CaseRejection = 1
					,CaseStatusTypeID = ( SELECT CaseStatusTypeID from Event.CaseStatusTypes WHERE CaseStatusType = 'Refused by Exec' )
			FROM	Meta.CaseDetails CD
			WHERE	CD.CaseID = @CaseID
		END
		IF @Rejection = 0
		BEGIN
			UPDATE Requirement.SelectionRequirements
			SET RecordsRejected = ISNULL(RecordsRejected, 0) - 1
			WHERE RequirementID = @SelectionID
			
			UPDATE	CD
			SET		 CaseRejection = 0
					,CaseStatusTypeID = ( SELECT CaseStatusTypeID from Event.CaseStatusTypes WHERE CaseStatusType = 'Active' )
			FROM	Meta.CaseDetails CD
			WHERE	CD.CaseID = @CaseID
		END
		
	COMMIT TRAN
	
END TRY
BEGIN CATCH

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [Sample_Errors].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH				

