CREATE PROCEDURE [OWAP].[uspUpdateEventNonSolicitations]
@NonSolicitationTypeDesc NVARCHAR (100), @PartyToNonSolicitate [dbo].[PartyID], @EventToNonSolicitate [dbo].[EventID], @UserPartyID BIGINT=0, @NonSolicitationTextID TINYINT=0, @SessionID NVARCHAR (100)=N'', @AuditID BIGINT=0, @ErrorCode INT=0 OUTPUT
AS
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
		EXECUTE	[OWAP].[uspAuditSession] 'Manual Set Case Rejection', @UserPartyRoleID, @AuditID Output, @ErrorCode Output
	END
	--
	-- AUDIT THE ACTION AND GET THE RESULTANT AuditItemID
	--
	EXEC OWAP.uspAuditAction @AuditID, @ActionDate, @UserPartyID, @UserRoleTypeID, @AuditItemID OUTPUT, @ErrorCode OUTPUT

	INSERT	[Event].vwDA_NonSolicitations
	(
		NonSolicitationID,
		NonSolicitationTextID, 
		PartyID,
		EventID,
		FromDate,
		AuditItemID
	)
	VALUES	
	(
		0,
		@NonSolicitationTextID, 
		@PartyToNonSolicitate,
		@EventToNonSolicitate,
	    @ActionDate,
		@AuditItemID
	)

	CREATE TABLE #CasesToReject
	(
		ID INT IDENTITY (1,1),
		SelectionRequirementID BIGINT NULL,
		CaseID BIGINT NULL
	)

	INSERT INTO #CasesToReject
	(
		SelectionRequirementID,
		CaseID
	)
	SELECT	
			cd.SelectionRequirementID, 
			cd.CaseID
	FROM	Meta.CaseDetails cd
	JOIN	Requirement.SelectionRequirements sr on sr.RequirementID = cd.SelectionRequirementID AND SR.SelectionStatusTypeID BETWEEN 1 AND 4
	JOIN	Vehicle.Vehicles V on V.VehicleID = CD.VehicleID
	WHERE	cd.VIN = V.VIN
	AND		CD.CaseRejection = 0
	AND		CD.EventID = @EventToNonSolicitate
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
		
		DELETE #CasesToReject WHERE ID = @CasesToReject
		
		SET @CasesToReject = 0
		
		SELECT
			TOP 1
			@CasesToReject = ID,
			@CaseID = C.CaseID,
			@RequirementID = C.SelectionRequirementID
		FROM
			#CasesToReject C
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
