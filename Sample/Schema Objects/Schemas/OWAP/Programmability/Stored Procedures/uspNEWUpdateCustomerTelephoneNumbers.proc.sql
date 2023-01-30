CREATE PROCEDURE [OWAP].[uspNEWUpdateCustomerTelephoneNumbers]

		@SessionID [dbo].[SessionID]=null, 
		@AuditID [dbo].[AuditID]=null, 
		@UserPartyRoleID [dbo].[PartyRoleID]=null, 

		@PartyID		[dbo].[PartyID], 
		@HomeNumber		[dbo].[ContactNumber] = null,
		@WorkNumber		[dbo].[ContactNumber] = null,
		@MobileNumber	[dbo].[ContactNumber] = null,
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

		IF ( @SessionID IS NULL ) SELECT @SessionID = 'NEW OWAP Update Telephone Numbers'

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

		DECLARE @TelephoneUpdate Table
		(

			AuditItemID							BIGINT,
			PartyID								INT,
			HomeTelephoneNumber					NVARCHAR(70) null,
			WorkTelephoneNumber					NVARCHAR(70) null,
			MobileTelephoneNumber				NVARCHAR(70) null,
			[HomeTelephoneContactMechanismID]	INT null,
			[WorkTelephoneContactMechanismID]	INT null,
			[MobileNumberContactMechanismID]	INT null
		)

		INSERT @TelephoneUpdate (AuditItemID, PartyID, HomeTelePhoneNumber, WorkTelePhoneNumber, MobileTelePhoneNumber)
		SELECT @AuditItemID, @PartyID, LTRIM(RTRIM(ISNULL(@HomeNumber,''))), LTRIM(RTRIM(ISNULL(@WorkNumber,''))), LTRIM(RTRIM(ISNULL(@MobileNumber,'')))
	
	
	
	BEGIN TRAN


		-- HomeNumbers
		INSERT INTO ContactMechanism.vwDA_TelephoneNumbers
		(
			AuditItemID,
			ContactMechanismID,
			ContactNumber,
			ContactMechanismTypeID,
			Valid,
			TelephoneType -- we pass in null for this parameter as this is only used to write the ContactMechanismID back to the VWT which we are not using
		)
		SELECT 
				AuditItemID,
				ISNULL(HomeTelephoneContactMechanismID, 0) AS ContactMechanismID,
				HomeTelephoneNumber, 
				3,
				1 AS Valid,
				NULL AS TelephoneType
		FROM	@TelephoneUpdate
		--WHERE	LTRIM(RTRIM(ISNULL(HomeTelephoneNumber,''))) <> ''


		-- get the ContactMechanismIDs generated
		UPDATE		CUTN
		SET			CUTN.HomeTelephoneContactMechanismID = ATN.ContactMechanismID
		FROM		@TelephoneUpdate CUTN
		INNER JOIN	[$(Sample_Audit)].Audit.TelephoneNumbers ATN ON ATN.AuditItemID = CUTN.AuditItemID
		WHERE		ATN.ContactNumber = CUTN.HomeTelephoneNumber

		INSERT INTO ContactMechanism.vwDA_PartyContactMechanisms
		(
			AuditItemID,
			ContactMechanismID,
			PartyID,
			FromDate,
			ContactMechanismPurposeTypeID
		)
		SELECT
				AuditItemID,
				HomeTelephoneContactMechanismID,
				PartyID,
				GETDATE(),
				1
		FROM	@TelephoneUpdate
		WHERE	HomeTelephoneContactMechanismID <> 0

		
		
		
		-- WorkNumbers
		INSERT INTO ContactMechanism.vwDA_TelephoneNumbers
		(
			AuditItemID,
			ContactMechanismID,
			ContactNumber,
			ContactMechanismTypeID,
			Valid,
			TelephoneType -- we pass in null for this parameter as this is only used to write the ContactMechanismID back to the VWT which we are not using
		)
		SELECT 
				AuditItemID,
				ISNULL(WorkTelephoneContactMechanismID, 0) AS ContactMechanismID,
				WorkTelephoneNumber, 
				2,
				1 AS Valid,
				NULL AS TelephoneType
		FROM	@TelephoneUpdate
		--WHERE	LTRIM(RTRIM(ISNULL(WorkTelephoneNumber,''))) <> ''

		-- get the ContactMechanismIDs generated
		UPDATE		CUTN
		SET			CUTN.WorkTelephoneContactMechanismID = ATN.ContactMechanismID
		FROM		@TelephoneUpdate CUTN
		INNER JOIN	[$(Sample_Audit)].Audit.TelephoneNumbers ATN ON ATN.AuditItemID = CUTN.AuditItemID
		WHERE		ATN.ContactNumber = CUTN.WorkTelephoneNumber


		INSERT INTO ContactMechanism.vwDA_PartyContactMechanisms
		(
			AuditItemID,
			ContactMechanismID,
			PartyID,
			FromDate,
			ContactMechanismPurposeTypeID
		)
		SELECT
				AuditItemID,
				WorkTelephoneContactMechanismID,
				PartyID,
				GETDATE(),
				7
		FROM	@TelephoneUpdate
		WHERE	WorkTelephoneContactMechanismID <> 0
		
		
		
		-- MobileNumbers
		INSERT INTO ContactMechanism.vwDA_TelephoneNumbers
		(
			AuditItemID,
			ContactMechanismID,
			ContactNumber,
			ContactMechanismTypeID,
			Valid,
			TelephoneType -- we pass in null for this parameter as this is only used to write the ContactMechanismID back to the VWT which we are not using
		)
		SELECT 
				AuditItemID,
				ISNULL(MobileNumberContactMechanismID, 0) AS ContactMechanismID,
				MobileTelephoneNumber, 
				4,
				1 AS Valid,
				NULL AS TelephoneType
		FROM	@TelephoneUpdate
		--WHERE	LTRIM(RTRIM(ISNULL(MobileTelephoneNumber,''))) <> ''

		-- get the ContactMechanismIDs generated
		UPDATE		CUTN
		SET			CUTN.MobileNumberContactMechanismID = ATN.ContactMechanismID
		FROM		@TelephoneUpdate CUTN
		INNER JOIN	[$(Sample_Audit)].Audit.TelephoneNumbers ATN ON ATN.AuditItemID = CUTN.AuditItemID
		WHERE		ATN.ContactNumber = CUTN.MobileTelephoneNumber


		INSERT INTO ContactMechanism.vwDA_PartyContactMechanisms
		(
			AuditItemID,
			ContactMechanismID,
			PartyID,
			FromDate,
			ContactMechanismPurposeTypeID
		)
		SELECT
				AuditItemID,
				MobileNumberContactMechanismID,
				PartyID,
				GETDATE(),
				6
		FROM	@TelephoneUpdate
		WHERE	MobileNumberContactMechanismID <> 0

		
		
	COMMIT TRAN

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