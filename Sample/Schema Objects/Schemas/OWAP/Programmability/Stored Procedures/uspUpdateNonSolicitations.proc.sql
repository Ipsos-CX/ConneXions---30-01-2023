CREATE PROCEDURE [OWAP].[uspUpdateNonSolicitations] 
(	
	@NonSolicitationTypeDesc NVARCHAR(100), 
	@PartyToNonSolicitate [dbo].[PartyID],	-- which party to non-solictate
	@UserPartyID BIGINT = 0,				-- Current user requesting non-solicitation
	@NonSolicitationTextID TINYINT = 0,		-- from dbo.nonsolicitaiontext.@NonSolicitationTextID : Reason
	@SessionID NVARCHAR(100) = N'',			-- Current owap session
	@AuditID BIGINT = 0,					-- supplied by owap or sp generated if 0 i.e. manual
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

	DECLARE @CasesToReject BIGINT = 0
	DECLARE @CaseID dbo.CaseId = 0
	DECLARE @RequirementID dbo.RequirementID = 0
	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

	SET XACT_ABORT ON	

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
	BEGIN TRY
			
	BEGIN TRAN
	
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

	INSERT	Party.vwDA_NonSolicitations 
	(
		NonSolicitationID,
		NonSolicitationTextID, 
		PartyID,
		FromDate,
		AuditItemID
	)
	VALUES	
	(
		0,
		@NonSolicitationTextID, 
		@PartyToNonSolicitate,
	    @ActionDate,
		@AuditItemID
	)

	CREATE TABLE #CasesToreject
	(
		ID INT IDENTITY (1,1),
		SelectionRequirementID BIGINT NULL,
		CaseID BIGINT NULL
	)

	INSERT INTO #CasesToreject
	(
		SelectionRequirementID,
		CaseID
	)
	SELECT	
			cd.SelectionRequirementID, 
			cd.CaseID
	FROM	Sample.Meta.CaseDetails cd
	JOIN	Sample.Requirement.SelectionRequirements sr on sr.RequirementID = cd.SelectionRequirementID AND SR.SelectionStatusTypeID BETWEEN 1 AND 4
	JOIN	Sample.Vehicle.Vehicles V on V.VehicleID = CD.VehicleID
	WHERE	cd.VIN = V.VIN
	AND		CD.CaseRejection = 0
	AND		CD.PartyID = @PartyToNonSolicitate
	GROUP	BY 
			cd.SelectionRequirementID, 
			sr.SelectionStatusTypeID, 
			cd.CaseID
	SELECT
		TOP 1
		@CasesToReject = C.ID,
		@CaseID = C.CaseID,
		@RequirementID = C.SelectionRequirementID
	FROM
		#CasesToreject C
	
	WHILE ( @CasesToReject > 0 )
	BEGIN

		EXEC [OWAP].[uspSetCaseRejection]
			@CaseID = @CaseID, 
			@Rejection = 1, 
			@SelectionID = @RequirementID, 
			@SessionID = @SessionID, 
			@AuditID = @AuditID, 
			@UserPartyID = @UserPartyID, 
			@ErrorCode = 0
		
		DELETE #CasesToreject WHERE ID = @CasesToReject
		
		SET @CasesToReject = 0
		
		SELECT
			TOP 1
			@CasesToReject = ID,
			@CaseID = C.CaseID,
			@RequirementID = C.SelectionRequirementID
		FROM
			#CasesToreject C
	END


	IF ( @@TRANCOUNT > 0 )
	BEGIN
		COMMIT
	END
	
	SET @ErrorCode = 0
	
END TRY
BEGIN CATCH

	IF ( @@TRANCOUNT > 0 )
	BEGIN
		ROLLBACK
	END

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

