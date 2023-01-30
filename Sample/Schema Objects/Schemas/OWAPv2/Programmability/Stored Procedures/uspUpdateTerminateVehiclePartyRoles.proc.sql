CREATE    PROCEDURE [OWAPv2].[uspUpdateTerminateVehiclePartyRoles]
(
	@SessionID NVARCHAR(100),
	@PartyID INT, 
	@VehicleID INT, 
	@VehicleRoleTypeID TINYINT = NULL, 
	@ThroughDate DATETIME = NULL, 
	@AuditID BIGINT = NULL,
	@UserPartyID INT = NULL,
	@ErrorCode INT = 0 OUTPUT
)
AS
/*

Version		Date		Aurthor			Why
------------------------------------------------------------------------------------------------------
1.0			11/06/2004	Mark Davidson	Created
1.1			06/06/2012	Pardip Mudhar	Modified for connexion application
1.2			01/03/2013	Pardip Mudhar	Reject live cases for the terminated vehicle
1.3			14/09/2016	Chris Ross		Move to schema OWAPv2
1.4			21/01/2020	Chris Ledger	BUG 15372: Fix Hard coded references to databases.	
*/

SET NOCOUNT ON

--Rollback on error
	SET XACT_ABORT ON	

--Declare local variables
	DECLARE @AuditItemID BIGINT
	DECLARE @UserID INT
	DECLARE @RoleTypeID SMALLINT
	DECLARE @UserPartyRoleID BIGINT = 0
	DECLARE @UserRoleTypeID dbo.PartyRoleID
	DECLARE @ActionDate DATETIME = NULL
	DECLARE @FromDate DATETIME = NULL
	DECLARE @CaseID [dbo].[CaseID] = NULL
	DECLARE @RequirementID [dbo].[RequirementID] = NULL
	DECLARE @SelectionStatus INT = 0
	DECLARE @CasesToReject INT = 0

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)	

--Validate Parameters
	SET @AuditItemID = ISNULL(@AuditItemID, 0)
	SET @ThroughDate = ISNULL(@ThroughDate, CURRENT_TIMESTAMP)
	SET @ActionDate = GETDATE()

BEGIN TRY	
--Get AuditID from SessionID
		--		
		-- GET THE USER DETAILS
		--
		IF ( ISNULL( @UserPartyID, 0 ) = 0 OR @UserPartyID = -1 )
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
		--
		-- Check Audit id supplied or running as single module (-1) or get an audit id
		--
		IF (ISNULL( @AuditID, 0 ) = 0 OR @AuditID = -1 )
		BEGIN
			EXECUTE	[OWAP].[uspAuditSession] 'Manual Set Case Rejection', @userPartyRoleID, @AuditID Output, @ErrorCode Output
		END		
		-- AUDIT THE ACTION AND GET THE RESULTANT AuditItemID
		
		EXEC OWAP.uspAuditAction @AuditID, @ActionDate, @UserPartyID, @UserRoleTypeID, @AuditItemID OUTPUT, @ErrorCode OUTPUT

--Perform Update
/*
	If role is specified, just terminate this role
	otherwise, terminate all roles.
	This branch is called by owap when user clicks 'mark car as sold'
	This must also deal with situations where 'Registered Owner' role
	does not exist.  In these cases, this must be added.
*/
	IF @VehicleRoleTypeID IS NULL
		BEGIN
			IF NOT EXISTS 
			(
				SELECT 
					vpr.VehicleID 
				FROM 
					[Vehicle].vwDA_VehiclePartyRoles AS vpr 
				WHERE 
					vpr.VehicleID = @VehicleID
					AND vpr.PartyID = @PartyID
					AND vpr.VehicleRoleTypeID = 2 --Registered Owner
			)
				BEGIN

					INSERT INTO
						[Vehicle].vwDA_VehiclePartyRoles
						(
							PartyID, 
							VehicleRoleTypeID, 
							VehicleID, 
							AuditItemID, 
							FromDate
						)
					SELECT
						@PartyID AS PartyID, 
						2 AS VehicleRoleTypeID, --Registered Owner
						@VehicleID AS VehicleID, 
						@AuditItemID AS AuditItemID, 
						@ThroughDate AS FromDate
				END
----Terminate all roles
			UPDATE 
				[Vehicle].vwDA_VehiclePartyRoles
			SET
				AuditItemID = @AuditItemID, 
				ThroughDate = @ThroughDate
			WHERE
				PartyID = @PartyID
				AND VehicleID = @VehicleID
				AND ThroughDate IS NULL
		END
	ELSE
		BEGIN
			--
			-- Terminate specific role
			--
			SELECT @FromDate = VPR.ThroughDate
			FROM Vehicle.Vehicles V
			JOIN Vehicle.VehiclePartyRoles VPR on VPR.VehicleID = V.VehicleID  AND VPR.PartyID = @PartyID
			WHERE V.VehicleID = @VehicleID 
			
			UPDATE 
				[Vehicle].vwDA_VehiclePartyRoles
			SET
				AuditItemID = @AuditItemID, 
				ThroughDate = @ThroughDate
			WHERE
				PartyID = @PartyID
				AND VehicleID = @VehicleID
				AND VehicleRoleTypeID = @VehicleRoleTypeID
				AND FromDate BETWEEN @FromDate AND DATEADD(day, 1, @FromDate)
				AND ThroughDate IS NULL
		END
	
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
	FROM	Meta.CaseDetails cd
	JOIN	Requirement.SelectionRequirements sr on sr.RequirementID = cd.SelectionRequirementID AND SR.SelectionStatusTypeID BETWEEN 1 AND 4
	JOIN	Vehicle.Vehicles V on V.VehicleID = @VehicleID
	WHERE	cd.VIN = V.VIN
	AND		CD.CaseRejection = 0
	AND		CD.PartyID = @PartyID
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
	
END TRY
BEGIN CATCH

	SET @ErrorCode = @@Error

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

