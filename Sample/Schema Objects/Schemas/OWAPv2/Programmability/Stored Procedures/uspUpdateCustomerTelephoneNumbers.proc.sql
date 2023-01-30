CREATE PROCEDURE [OWAPv2].[uspUpdateCustomerTelephoneNumbers]
		@SessionID [dbo].[SessionID]=null, @AuditID [dbo].[AuditID]=null, @UserPartyRoleID [dbo].[PartyRoleID]=null, @PartyID [dbo].[PartyID], @HomeNumber [dbo].[ContactNumber] = null, @WorkNumber [dbo].[ContactNumber] = null, @MobileNumber [dbo].[ContactNumber] = null, @RowCount INT OUTPUT, @ErrorCode INT OUTPUT
AS

/*
	Purpose:	Update Customer Telephone Numbers and Best Party Telephone Numbers table
		
	Version			Date			Developer			Comment
	1.0				2016-10-14		Chris Ledger		Created
	1.1				2020-01-21		Chris Ledger		BUG 15372: Fix Hard coded references to databases.	
*/

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

	----------------------------------------------------
	-- get basic OWAPAdmin user details of manually setting data updates
	----------------------------------------------------
	IF ( @UserPartyRoleID IS NULL)
	BEGIN
			SELECT @UserPartyRoleID = pr.PartyRoleID 
			FROM OWAP.Users U
			INNER JOIN Party.PartyRoles pr ON pr.PartyID = u.PartyID AND pr.RoleTypeID = 51 -- OWAP
			WHERE U.UserName = 'OWAPAdmin'	
	END	

	----------------------------------------------------
	-- GET THE USER DETAILS
	----------------------------------------------------
	SELECT
		@UserPartyID = PR.PartyID,
		@UserRoleTypeID = PR.RoleTypeID
	FROM Party.PartyRoles PR
	INNER JOIN OWAP.Users U ON U.PartyID = PR.PartyID AND U.RoleTypeID = PR.RoleTypeID
	WHERE PR.PartyRoleID = @UserPartyRoleID
	
	--------------------------------------------------------------------
	-- AUDIT THE ACTION AND GET THE RESULTANT AuditItemID
	--------------------------------------------------------------------
	EXEC [OWAP].[uspAuditSession] @SessionID, @userPartyRoleID, @AuditID Output, @ErrorCode Output
	EXEC OWAP.uspAuditAction @AuditID, @ActionDate, @UserPartyID, @UserRoleTypeID, @AuditItemID OUTPUT, @ErrorCode OUTPUT


	--------------------------------------------------------------------
	-- CREATE UPDATE TABLE AND CHECKSUM VARIABLES
	--------------------------------------------------------------------
	DECLARE @TelephoneUpdate Table
	(
		AuditItemID							BIGINT,
		PartyID								INT,
		HomeTelephoneNumber					NVARCHAR(70) NULL,
		WorkTelephoneNumber					NVARCHAR(70) NULL,
		MobileTelephoneNumber				NVARCHAR(70) NULL,
		[HomeTelephoneContactMechanismID]	INT NULL,
		[WorkTelephoneContactMechanismID]	INT NULL,
		[MobileNumberContactMechanismID]	INT NULL,
		[HomeNumberIsCurrentForParty]		[bit] NULL,
		[WorkNumberIsCurrentForParty]		[bit] NULL,
		[MobileNumberIsCurrentForParty]		[bit] NULL
	)

	INSERT @TelephoneUpdate (AuditItemID, PartyID, HomeTelephoneNumber, WorkTelephoneNumber, MobileTelephoneNumber)
	SELECT @AuditItemID, @PartyID, LTRIM(RTRIM(ISNULL(@HomeNumber,''))), LTRIM(RTRIM(ISNULL(@WorkNumber,''))), LTRIM(RTRIM(ISNULL(@MobileNumber,'')))

	DECLARE @HomeNumberCheckSum BIGINT = 0 
	SELECT 	@HomeNumberCheckSum = CHECKSUM(ISNULL(@HomeNumber,''))

	DECLARE @WorkNumberCheckSum BIGINT = 0 
	SELECT 	@WorkNumberCheckSum = CHECKSUM(ISNULL(@WorkNumber,''))

	DECLARE @MobileNumberCheckSum BIGINT = 0 
	SELECT 	@MobileNumberCheckSum = CHECKSUM(ISNULL(@MobileNumber,''))
	--------------------------------------------------------------------


	--------------------------------------------------------------------
	--CHECK IF TELEPHONE NUMBERS ALREADY ASSOCIATED TO THE PARTY AND UPDATE @TelephoneUpdate
	--------------------------------------------------------------------
	-- HOME NUMBERS
	UPDATE TU SET TU.HomeNumberIsCurrentForParty = 1, TU.HomeTelephoneContactMechanismID = PCM.ContactMechanismID
	FROM		[Meta].[PartyBestTelephoneNumbers] PBTN 
	INNER JOIN	[ContactMechanism].[PartyContactMechanisms] PCM ON PBTN.[HomeLandlineID] = PCM.[ContactMechanismID] AND PBTN.PartyID = PCM.PARTYID
	INNER JOIN [ContactMechanism].[ContactMechanisms] CM ON PCM.ContactMechanismID = CM.ContactMechanismID
			AND CM.ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (landline)')
	INNER JOIN [ContactMechanism].[PartyContactMechanismPurposes] PCMP ON PCMP.PartyID = PCM.PartyID
			AND PCMP.ContactMechanismID = PCM.ContactMechanismID
			AND PCMP.ContactMechanismPurposeTypeID = (SELECT ContactMechanismPurposeTypeID FROM ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Main home number')
	INNER JOIN	[ContactMechanism].[TelephoneNumbers] TN ON PCM.[ContactMechanismID] = TN.[ContactMechanismID]  AND TN.ContactNumberChecksum = @HomeNumberCheckSum
	INNER JOIN	@TelephoneUpdate TU	ON PCM.PartyID = TU.PartyID
	WHERE	PCM.PartyID = @PartyID

	-- WORK NUMBERS
	UPDATE TU SET TU.WorkNumberIsCurrentForParty = 1, TU.WorkTelephoneContactMechanismID = PCM.ContactMechanismID
	FROM		[Meta].[PartyBestTelephoneNumbers] PBTN 
	INNER JOIN	[ContactMechanism].[PartyContactMechanisms] PCM ON PBTN.[WorkLandlineID] = PCM.[ContactMechanismID] AND PBTN.PartyID = PCM.PARTYID
	INNER JOIN [ContactMechanism].[ContactMechanisms] CM ON PCM.ContactMechanismID = CM.ContactMechanismID
			AND CM.ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (landline)')
	INNER JOIN [ContactMechanism].[PartyContactMechanismPurposes] PCMP ON PCMP.PartyID = PCM.PartyID
			AND PCMP.ContactMechanismID = PCM.ContactMechanismID
			AND PCMP.ContactMechanismPurposeTypeID = (SELECT ContactMechanismPurposeTypeID FROM ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Work direct dial number')
	INNER JOIN	[ContactMechanism].[TelephoneNumbers] TN ON PCM.[ContactMechanismID] = TN.[ContactMechanismID]  AND TN.ContactNumberChecksum = @WorkNumberCheckSum
	INNER JOIN	@TelephoneUpdate TU	ON PCM.PartyID = TU.PartyID
	WHERE	PCM.PartyID = @PartyID

	-- MOBILE NUMBERS
	UPDATE TU SET TU.MobileNumberIsCurrentForParty = 1, TU.MobileNumberContactMechanismID = PCM.ContactMechanismID
	FROM		[Meta].[PartyBestTelephoneNumbers] PBTN 
	INNER JOIN	[ContactMechanism].[PartyContactMechanisms] PCM ON PBTN.[MobileID] = PCM.[ContactMechanismID] AND PBTN.PartyID = PCM.PARTYID
	INNER JOIN [ContactMechanism].[ContactMechanisms] CM ON PCM.ContactMechanismID = CM.ContactMechanismID
			AND CM.ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (mobile)')
	INNER JOIN	[ContactMechanism].[TelephoneNumbers] TN ON PCM.[ContactMechanismID] = TN.[ContactMechanismID]  AND TN.ContactNumberChecksum = @MobileNumberCheckSum
	INNER JOIN	@TelephoneUpdate TU	ON PCM.PartyID = TU.PartyID
	WHERE	PCM.PartyID = @PartyID
	--------------------------------------------------------------------


	--------------------------------------------------------------------
	--ONLY UPDATE TELEPHONE NUMBERS IF ANY ARE NEW FOR PARTY
	IF EXISTS ( SELECT *
				FROM @TelephoneUpdate TU
				WHERE (ISNULL(TU.HomeNumberIsCurrentForParty,0) <> 1 AND TU.HomeTelephoneNumber <> '') 
				OR (ISNULL(TU.WorkNumberIsCurrentForParty,0) <> 1 AND TU.WorkTelephoneNumber <> '') 
				OR (ISNULL(TU.MobileNumberIsCurrentForParty,0) <> 1 AND TU.MobileTelephoneNumber <> '')
				)	

	BEGIN
	
		BEGIN TRAN

		--------------------------------------------------------------------
		-- HOME NUMBERS
		--------------------------------------------------------------------
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
				(SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (landline)'),
				1 AS Valid,
				NULL AS TelephoneType
		FROM	@TelephoneUpdate
		WHERE	LTRIM(RTRIM(ISNULL(HomeTelephoneNumber,''))) <> '' AND ISNULL(HomeNumberIsCurrentForParty,0) <> 1

		-- GET ContactMechanismID GENERATED
		UPDATE		CUTN
		SET			CUTN.HomeTelephoneContactMechanismID = ATN.ContactMechanismID
		FROM		@TelephoneUpdate CUTN
		INNER JOIN	[$(AuditDB)].Audit.TelephoneNumbers ATN ON ATN.AuditItemID = CUTN.AuditItemID
		WHERE		ATN.ContactNumber = CUTN.HomeTelephoneNumber AND ISNULL(HomeNumberIsCurrentForParty,0) <> 1


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
				(SELECT ContactMechanismPurposeTypeID FROM ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Main home number')
		FROM	@TelephoneUpdate
		WHERE	HomeTelephoneContactMechanismID <> 0 AND ISNULL(HomeNumberIsCurrentForParty,0) <> 1
		--------------------------------------------------------------------

		
		--------------------------------------------------------------------		
		-- WORK NUMBERS
		--------------------------------------------------------------------
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
				(SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (landline)'),
				1 AS Valid,
				NULL AS TelephoneType
		FROM	@TelephoneUpdate
		WHERE	LTRIM(RTRIM(ISNULL(WorkTelephoneNumber,''))) <> '' AND ISNULL(WorkNumberIsCurrentForParty,0) <> 1

		-- GET ContactMechanismID GENERATED
		UPDATE		CUTN
		SET			CUTN.WorkTelephoneContactMechanismID = ATN.ContactMechanismID
		FROM		@TelephoneUpdate CUTN
		INNER JOIN	[$(AuditDB)].Audit.TelephoneNumbers ATN ON ATN.AuditItemID = CUTN.AuditItemID
		WHERE		ATN.ContactNumber = CUTN.WorkTelephoneNumber AND ISNULL(WorkNumberIsCurrentForParty,0) <> 1


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
				(SELECT ContactMechanismPurposeTypeID FROM ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Work direct dial number')
		FROM	@TelephoneUpdate
		WHERE	WorkTelephoneContactMechanismID <> 0 AND ISNULL(WorkNumberIsCurrentForParty,0) <> 1
		--------------------------------------------------------------------
		
		
		--------------------------------------------------------------------
		-- MOBILE NUMBERS
		--------------------------------------------------------------------
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
				(SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (mobile)'),
				1 AS Valid,
				NULL AS TelephoneType
		FROM	@TelephoneUpdate
		WHERE	LTRIM(RTRIM(ISNULL(MobileTelephoneNumber,''))) <> '' AND ISNULL(MobileNumberIsCurrentForParty,0) <> 1

		-- GET ContactMechanismID GENERATED
		UPDATE		CUTN
		SET			CUTN.MobileNumberContactMechanismID = ATN.ContactMechanismID
		FROM		@TelephoneUpdate CUTN
		INNER JOIN	[$(AuditDB)].Audit.TelephoneNumbers ATN ON ATN.AuditItemID = CUTN.AuditItemID
		WHERE		ATN.ContactNumber = CUTN.MobileTelephoneNumber AND ISNULL(MobileNumberIsCurrentForParty,0) <> 1


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
				(SELECT ContactMechanismPurposeTypeID FROM ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Private mobile number')
		FROM	@TelephoneUpdate
		WHERE	MobileNumberContactMechanismID <> 0 AND ISNULL(MobileNumberIsCurrentForParty,0) <> 1
		--------------------------------------------------------------------


		--------------------------------------------------------------------
		-- DELETE Meta.PartyBestTelephoneNumbers FOR PARTYID
		--------------------------------------------------------------------
		DELETE FROM Meta.PartyBestTelephoneNumbers
		WHERE PartyID = @PartyID
		--------------------------------------------------------------------

		--------------------------------------------------------------------
		-- GET BEST PARTY TELEPHONE NUMBERS FOR PARTYID AND INSERT INTO Meta.PartyBestTelephoneNumbers TABLE
		--------------------------------------------------------------------
		INSERT INTO Meta.PartyBestTelephoneNumbers
		(PartyID, PhoneID, LandlineID, HomeLandlineID, WorkLandlineID, MobileID)

		SELECT
			PCM.PartyID,
			MAX(P.ContactMechanismID) AS PhoneID,
			MAX(L.ContactMechanismID) AS LandlineID,
			MAX(H.ContactMechanismID) AS HomeLandlineID,
			MAX(W.ContactMechanismID) AS WorkLandlineID,
			MAX(M.ContactMechanismID) AS MobileID
		FROM ContactMechanism.PartyContactMechanisms PCM
		LEFT JOIN (
			SELECT
				PCM.PartyID,
				MAX(PCM.ContactMechanismID) AS ContactMechanismID
			FROM ContactMechanism.PartyContactMechanisms PCM
			JOIN ContactMechanism.ContactMechanisms CM ON PCM.ContactMechanismID = CM.ContactMechanismID
			JOIN ContactMechanism.TelephoneNumbers TN ON CM.ContactMechanismID = TN.ContactMechanismID
			WHERE CM.Valid = 1
			AND ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone')
			AND NOT EXISTS (
				SELECT * 
				FROM dbo.NonSolicitations NS
				JOIN ContactMechanism.NonSolicitations CMNS ON NS.NonSolicitationID = CMNS.NonSolicitationID
				WHERE NS.PartyID = PCM.PartyID
				AND CMNS.ContactMechanismID = PCM.ContactMechanismID
				AND GETDATE() >= NS.FromDate
				AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')
			)
			GROUP BY PCM.PartyID
		) P ON P.ContactMechanismID = PCM.ContactMechanismID AND P.PartyID = PCM.PartyID
		LEFT JOIN (
			SELECT
				PCM.PartyID,
				MAX(PCM.ContactMechanismID) AS ContactMechanismID
			FROM ContactMechanism.PartyContactMechanisms PCM
			JOIN ContactMechanism.ContactMechanisms CM ON PCM.ContactMechanismID = CM.ContactMechanismID
			JOIN ContactMechanism.TelephoneNumbers TN ON CM.ContactMechanismID = TN.ContactMechanismID
			WHERE CM.Valid = 1
			AND ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (landline)')
			AND NOT EXISTS (
				SELECT * 
				FROM dbo.NonSolicitations NS
				JOIN ContactMechanism.NonSolicitations CMNS ON NS.NonSolicitationID = CMNS.NonSolicitationID
				WHERE NS.PartyID = PCM.PartyID
				AND CMNS.ContactMechanismID = PCM.ContactMechanismID
				AND GETDATE() >= NS.FromDate
				AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')
			)
			GROUP BY PCM.PartyID
		) L ON L.ContactMechanismID = PCM.ContactMechanismID AND L.PartyID = PCM.PartyID
		LEFT JOIN (
			SELECT
				PCM.PartyID,
				MAX(PCM.ContactMechanismID) AS ContactMechanismID
			FROM ContactMechanism.PartyContactMechanisms PCM
			JOIN ContactMechanism.ContactMechanisms CM ON PCM.ContactMechanismID = CM.ContactMechanismID
			JOIN ContactMechanism.TelephoneNumbers TN ON CM.ContactMechanismID = TN.ContactMechanismID
			JOIN ContactMechanism.PartyContactMechanismPurposes PCMP ON PCMP.PartyID = PCM.PartyID
								AND PCMP.ContactMechanismID = PCM.ContactMechanismID
			WHERE CM.Valid = 1
			AND CM.ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (landline)')
			AND PCMP.ContactMechanismPurposeTypeID = (SELECT ContactMechanismPurposeTypeID FROM ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Main home number')
			AND NOT EXISTS (
				SELECT * 
				FROM dbo.NonSolicitations NS
				JOIN ContactMechanism.NonSolicitations CMNS ON NS.NonSolicitationID = CMNS.NonSolicitationID
				WHERE NS.PartyID = PCM.PartyID
				AND CMNS.ContactMechanismID = PCM.ContactMechanismID
				AND GETDATE() >= NS.FromDate
				AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')
			)
			GROUP BY PCM.PARTYID
		) H ON H.ContactMechanismID = PCM.ContactMechanismID AND H.PartyID = PCM.PartyID
		LEFT JOIN (
			SELECT
				PCM.PartyID,
				MAX(PCM.ContactMechanismID) AS ContactMechanismID
			FROM ContactMechanism.PartyContactMechanisms PCM
			JOIN ContactMechanism.ContactMechanisms CM ON PCM.ContactMechanismID = CM.ContactMechanismID
			JOIN ContactMechanism.TelephoneNumbers TN ON CM.ContactMechanismID = TN.ContactMechanismID
			JOIN ContactMechanism.PartyContactMechanismPurposes PCMP ON PCMP.PartyID = PCM.PartyID
								AND PCMP.ContactMechanismID = PCM.ContactMechanismID
			WHERE CM.Valid = 1
			AND CM.ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (landline)')
			AND PCMP.ContactMechanismPurposeTypeID = (SELECT ContactMechanismPurposeTypeID FROM ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Work direct dial number')
			AND NOT EXISTS (
				SELECT * 
				FROM dbo.NonSolicitations NS
				JOIN ContactMechanism.NonSolicitations CMNS ON NS.NonSolicitationID = CMNS.NonSolicitationID
				WHERE NS.PartyID = PCM.PartyID
				AND CMNS.ContactMechanismID = PCM.ContactMechanismID
				AND GETDATE() >= NS.FromDate
				AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')
			)
			GROUP BY PCM.PARTYID
		) W ON W.ContactMechanismID = PCM.ContactMechanismID AND W.PartyID = PCM.PartyID
		LEFT JOIN (
			SELECT
				PCM.PartyID,
				MAX(PCM.ContactMechanismID) AS ContactMechanismID
			FROM ContactMechanism.PartyContactMechanisms PCM
			JOIN ContactMechanism.ContactMechanisms CM ON PCM.ContactMechanismID = CM.ContactMechanismID
			JOIN ContactMechanism.TelephoneNumbers TN ON CM.ContactMechanismID = TN.ContactMechanismID
			WHERE CM.Valid = 1
			AND ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (mobile)')
			AND NOT EXISTS (
				SELECT * 
				FROM dbo.NonSolicitations NS
				JOIN ContactMechanism.NonSolicitations CMNS ON NS.NonSolicitationID = CMNS.NonSolicitationID
				WHERE NS.PartyID = PCM.PartyID
				AND CMNS.ContactMechanismID = PCM.ContactMechanismID
				AND GETDATE() >= NS.FromDate
				AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')
			)
			GROUP BY PCM.PartyID
		) M ON M.ContactMechanismID = PCM.ContactMechanismID AND M.PartyID = PCM.PartyID

		WHERE PCM.PartyID = @PartyID 
		AND NOT EXISTS (
			SELECT * 
			FROM dbo.NonSolicitations NS
			JOIN Party.NonSolicitations PNS ON NS.NonSolicitationID = PNS.NonSolicitationID
			WHERE NS.PartyID = PCM.PartyID
			AND GETDATE() >= NS.FromDate
			AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')
		)
		AND NOT EXISTS (
			SELECT * 
			FROM dbo.NonSolicitations NS
			JOIN ContactMechanism.ContactMechanismTypeNonSolicitations CMTNS ON NS.NonSolicitationID = CMTNS.NonSolicitationID
			WHERE NS.PartyID = PCM.PartyID
			AND CMTNS.ContactMechanismTypeID IN (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType IN ('Phone', 'Phone (landline)', 'Phone (mobile)'))
			AND GETDATE() >= NS.FromDate
			AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')
		)
		AND NOT COALESCE(	
			P.PartyID,
			L.PartyID,
			H.PartyID,
			W.PartyID,
			M.PartyID,
			0
		) = 0
		GROUP BY PCM.PartyID
		--------------------------------------------------------------------
		
		
		COMMIT TRAN
	
	END

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