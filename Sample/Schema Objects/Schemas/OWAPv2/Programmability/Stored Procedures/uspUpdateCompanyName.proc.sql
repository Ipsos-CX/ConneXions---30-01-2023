CREATE PROCEDURE [OWAPv2].[uspUpdateCompanyName]

		@SessionID			[dbo].[SessionID]=null, 
		@AuditID			[dbo].[AuditID]=null, 
		@UserPartyRoleID	[dbo].[PartyRoleID]=null, 

		@PartyID			[dbo].[PartyID], 
		@OrganisationName	[dbo].[OrganisationName],

		@RowCount INT OUTPUT, 
		@ErrorCode INT OUTPUT

AS
SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY
		
		DECLARE @AuditItemID dbo.AuditItemID
		DECLARE @ActionDate DATETIME2
		DECLARE @UserPartyID dbo.PartyID
		DECLARE @UserRoleTypeID dbo.RoleTypeID

		
		SET @ActionDate = GETDATE()

		IF ( @SessionID IS NULL ) SELECT @SessionID = 'NEW OWAP Update Company Name'

		-- get basic OWAPAdmin user details of manually setting data updates
		--
		IF ( @UserPartyRoleID IS NULL)
		BEGIN
				SELECT @UserPartyRoleID = pr.PartyRoleID 
				FROM OWAP.Users U
				INNER JOIN Party.PartyRoles pr ON pr.PartyID = u.PartyID AND pr.RoleTypeID = 51 -- OWAP
				WHERE U.UserName = 'OWAPAdmin'	
		END	
		--
		-- GET THE USER DETAILS
		--
		SELECT
			@UserPartyID = PR.PartyID,
			@UserRoleTypeID = PR.RoleTypeID
		FROM Party.PartyRoles PR
		INNER JOIN OWAP.Users U ON U.PartyID = PR.PartyID AND U.RoleTypeID = PR.RoleTypeID
		WHERE PR.PartyRoleID = @UserPartyRoleID
		
		-- AUDIT THE ACTION AND GET THE RESULTANT AuditItemID
		EXEC [OWAP].[uspAuditSession] @SessionID, @userPartyRoleID, @AuditID Output, @ErrorCode Output
		EXEC OWAP.uspAuditAction @AuditID, @ActionDate, @UserPartyID, @UserRoleTypeID, @AuditItemID OUTPUT, @ErrorCode OUTPUT


			UPDATE	[Party].[vwDA_LegalOrganisations] 
			SET		AuditItemID			= @AuditItemID,
					OrganisationName	= LTRIM(RTRIM(@OrganisationName)),
					Fromdate			= Getdate()
								
			WHERE	PartyID				= @PartyID AND  LTRIM(RTRIM(ISNULL(@OrganisationName,''))) <> ''


	SET @RowCount = @@RowCount
	SET @ErrorCode = ISNULL(Error_Number(), 0)

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
