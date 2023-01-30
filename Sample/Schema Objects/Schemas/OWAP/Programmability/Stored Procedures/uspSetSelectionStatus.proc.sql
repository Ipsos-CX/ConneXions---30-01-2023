CREATE PROC OWAP.uspSetSelectionStatus
(
		@SelectionID dbo.RequirementID, 
		@SessionID dbo.SessionID,
		@AuditID dbo.AuditID  = 0,
		@UserPartyID [dbo].PartyID = 0,
		@Status VARCHAR(20),
		@ErrorCode INT OUTPUT
)

AS

/*
	Purpose:	Update the status of a given selection and audit it. 
				Status must be "Authorised" or "Viewed"
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created
	1.1				20-May-2011		Pardip Mudhar		Update for new owap

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
		DECLARE @SelectionStatusTypeID dbo.SelectionStatusTypeID
		DECLARE @UserPartyRoleID dbo.PartyRoleID
		DECLARE @UserRoleTypeID dbo.PartyRoleID
						
		SET @ActionDate = GETDATE()
		
		SELECT @SelectionStatusTypeID = SelectionStatusTypeID
		FROM Requirement.SelectionStatusTypes
		WHERE SelectionStatusType = @Status
		--		
		-- GET THE USER DETAILS
		--
		IF ( ISNULL( @UserPartyID, 0 ) = 0 )
		BEGIN
			SELECT
				 @UserPartyID = VU.PartyID
				,@UserPartyRoleID = VU.PartyRoleID
				,@UserRoleTypeID = VU.RoleTypeID
			FROM
				OWAP.vwUsers VU
			WHERE
				VU.UserName = 'OWAPAdmin'
		END
		ELSE
		BEGIN
			SELECT
				 @UserPartyRoleID = VU.PartyRoleID
				,@UserRoleTypeID = VU.RoleTypeID
			FROM
				OWAP.vwUsers VU
			WHERE
				VU.PartyID = @UserPartyID
		END
		
		IF (ISNULL( @AuditID, 0 ) = 0 )
		BEGIN
			EXECUTE	[OWAP].[uspAuditSession] 'Manual Set Case Rejection', @userPartyRoleID, @AuditID Output, @ErrorCode Output
		END		
		-- AUDIT THE ACTION AND GET THE RESULTANT AuditItemID
		
		EXEC OWAP.uspAuditAction @AuditID, @ActionDate, @UserPartyID, @UserRoleTypeID, @AuditItemID OUTPUT, @ErrorCode OUTPUT

		-- UPDATE THE SELECTION STATUS
		IF @Status = 'Viewed'
		BEGIN
			UPDATE [$(SampleDB)].Requirement.vwDA_SelectionRequirements
			SET	AuditItemID = @AuditItemID,
				SelectionStatusTypeID = @SelectionStatusTypeID,
				LastViewedDate = @ActionDate,
				LastViewedPartyID = @UserPartyID,
				LastViewedRoleTypeID = @UserRoleTypeID
			WHERE RequirementID = @SelectionID
		END
		
		IF @Status = 'Authorised'
		BEGIN
			UPDATE [$(SampleDB)].Requirement.vwDA_SelectionRequirements
			SET	AuditItemID = @AuditItemID,
				SelectionStatusTypeID = @SelectionStatusTypeID,
				DateOutputAuthorised = @ActionDate,
				AuthorisingPartyID = @UserPartyID,
				AuthorisingRoleTypeID = @UserRoleTypeID
			WHERE RequirementID = @SelectionID
		END
		--
		-- Re-Authorise selection output 
		-- only user with role type 51/53 
		-- Initialliy set the status of requirement to null and update to Selected so that a audit trail is created
		--
		IF (@Status = 'Re-Authorise' )
		BEGIN
			UPDATE [$(SampleDB)].Requirement.SelectionRequirements
			SET DateOutputAuthorised = null,
				AuthorisingPartyID = @UserPartyID,
				AuthorisingRoleTypeID = @UserRoleTypeID,
				SelectionStatusTypeID = (SELECT SST.SelectionStatusTypeID FROM [$(SampleDB)].Requirement.SelectionStatusTypes SST WHERE SST.SelectionStatusType = 'Selected')
			WHERE RequirementID = @SelectionID
			
			UPDATE Requirement.vwDA_SelectionRequirements
			SET	AuditItemID = @AuditItemID,
				SelectionStatusTypeID = (SELECT SST.SelectionStatusTypeID FROM [$(SampleDB)].Requirement.SelectionStatusTypes SST WHERE SST.SelectionStatusType = 'Selected'),
				DateOutputAuthorised = NULL,
				AuthorisingPartyID = @UserPartyID,
				AuthorisingRoleTypeID = @UserRoleTypeID
			WHERE RequirementID = @SelectionID
		END

		SET @ErrorCode = ISNULL(Error_Number(), 0)
		
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

	SET @ErrorCode = @ErrorNumber

	IF (@@TRANCOUNT > 0 )
	BEGIN
		ROLLBACK
	END

	EXEC [Sample_Errors].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH	

