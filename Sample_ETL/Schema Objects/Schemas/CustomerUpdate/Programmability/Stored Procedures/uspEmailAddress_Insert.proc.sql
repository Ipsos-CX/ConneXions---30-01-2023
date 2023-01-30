CREATE PROCEDURE [CustomerUpdate].[uspEmailAddress_Insert]

AS
SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


	BEGIN TRAN
	
		-- get the email address type
		DECLARE @EmailPurposeTypeID dbo.ContactMechanismTypeID
		
		SELECT @EmailPurposeTypeID = ContactMechanismTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'E-mail address'

		-- get the various purpose types we may use
		DECLARE @UnknownEmailPurposeTypeID dbo.ContactMechanismPurposeTypeID
		DECLARE @PrivateEmailPurposeTypeID dbo.ContactMechanismPurposeTypeID
		DECLARE @WorkEmailPurposeTypeID dbo.ContactMechanismPurposeTypeID
		DECLARE @MainEmailPurposeTypeID dbo.ContactMechanismPurposeTypeID
		
		SELECT @UnknownEmailPurposeTypeID = ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'e-mail address (unknown purpose)'
		SELECT @PrivateEmailPurposeTypeID = ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Private e-mail address'
		SELECT @WorkEmailPurposeTypeID = ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Work e-mail address'
		SELECT @MainEmailPurposeTypeID = ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Main business e-mail address'
		
		-- first of all check if we've already got the supplied email address for the party
		UPDATE CUEA
		SET
			CUEA.ContactMechanismID = EA.ContactMechanismID,
			CUEA.ContactMechanismPurposeTypeID = ISNULL(PCMP.ContactMechanismPurposeTypeID, @UnknownEmailPurposeTypeID) -- if null use e-mail address (unknown purpose)
		FROM CustomerUpdate.EmailAddress CUEA
		INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON PCM.PartyID = CUEA.PartyID
		INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = PCM.ContactMechanismID
									AND EA.EmailAddress = CUEA.EmailAddress
		LEFT JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanismPurposes PCMP ON PCMP.ContactMechanismID = CUEA.ContactMechanismID
										AND PCMP.PartyID = CUEA.PartyID

		-- get the maximum ContactMechanismID for each party we've matched with an existing email
		-- and if it matches with the matched ContactMechanismID set the EmailIsCurrentForParty value to 1 so that these are not loaded into the ODS, just audit
		UPDATE CUEA
		SET CUEA.EmailIsCurrentForParty = 1
		FROM CustomerUpdate.EmailAddress CUEA
		INNER JOIN (
			SELECT
				CUEA.PartyID,
				CUEA.CaseID,
				MAX(EA.ContactMechanismID) AS MaxContactMechanismID
			FROM CustomerUpdate.EmailAddress CUEA
			INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON PCM.PartyID = CUEA.PartyID
			INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = PCM.ContactMechanismID
			WHERE ISNULL(ContactMechanismPurposeTypeID, 0) > 0
			GROUP BY CUEA.PartyID, CUEA.CaseID
		) M ON M.PartyID = CUEA.PartyID
			AND M.CaseID = CUEA.CaseID
			AND M.MaxContactMechanismID = CUEA.ContactMechanismID

		-- remove the existing party to contact mechanisms links for emails that are not the most recent for the party
		DELETE PCMP
		FROM CustomerUpdate.EmailAddress CUEA
		INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanismPurposes PCMP ON PCMP.PartyID = CUEA.PartyID
							AND PCMP.ContactMechanismID = CUEA.ContactMechanismID
		WHERE CUEA.ContactMechanismID IS NOT NULL
		AND CUEA.EmailIsCurrentForParty = 0

		DELETE PCM
		FROM CustomerUpdate.EmailAddress CUEA
		INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON PCM.PartyID = CUEA.PartyID
							AND PCM.ContactMechanismID = CUEA.ContactMechanismID
		WHERE CUEA.ContactMechanismID IS NOT NULL
		AND CUEA.EmailIsCurrentForParty = 0


		-- match the exact ContactMechanismPurposeTypes from list above and set ContactMechanismPurposeTypes
		UPDATE CUEA
		SET CUEA.ContactMechanismPurposeTypeID = CMPT.ContactMechanismPurposeTypeID
		FROM CustomerUpdate.EmailAddress CUEA
		INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes CMPT ON CMPT.ContactMechanismPurposeType = CUEA.ContactMechanismPurposeType
		WHERE ISNULL(CUEA.ContactMechanismPurposeTypeID, 0) = 0

		-- check for Private e-mail addresses using "home" and "private"
		UPDATE CustomerUpdate.EmailAddress
		SET ContactMechanismPurposeTypeID = @PrivateEmailPurposeTypeID
		WHERE ISNULL(ContactMechanismPurposeTypeID, 0) = 0
		AND (
			ContactMechanismPurposeType LIKE '%home%'
			OR
			ContactMechanismPurposeType LIKE '%private%'
		)

		-- check for Work e-mail addresses using "work"
		UPDATE CustomerUpdate.EmailAddress
		SET ContactMechanismPurposeTypeID = @WorkEmailPurposeTypeID
		WHERE ISNULL(ContactMechanismPurposeTypeID, 0) = 0
		AND ContactMechanismPurposeType LIKE '%work%'

		-- check for Main business e-mail addresses using "bus"
		UPDATE CustomerUpdate.EmailAddress
		SET ContactMechanismPurposeTypeID = @MainEmailPurposeTypeID
		WHERE ISNULL(ContactMechanismPurposeTypeID, 0) = 0
		AND ContactMechanismPurposeType LIKE '%bus%'


		/* LOAD INTO SAMPLE */

		-- Check the CaseID and PartyID combination is valid
		UPDATE CUEA
		SET CUEA.CasePartyCombinationValid = 1
		FROM CustomerUpdate.EmailAddress CUEA
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CUEA.CaseID
										AND AEBI.PartyID = CUEA.PartyID


		-- EmailAddresses
		-- This generates the ContactMechanismIDs and inserts into ContactMechanisms and EmailAddresses
		-- as well as audit
		INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_EmailAddresses
		(
			AuditItemID,
			ContactMechanismID,
			EmailAddress,
			EmailAddressChecksum,
			ContactMechanismTypeID,
			Valid,
			EmailAddressType -- we pass in null for this parameter as this is only used to write the ContactMechanismID back to the VWT which we are not using
		)
		SELECT 
			AuditItemID,
			ISNULL(ContactMechanismID, 0) AS ContactMechanismID,
			EmailAddress, 
			CHECKSUM(EmailAddress) AS EmailAddressChecksum,
			@EmailPurposeTypeID AS ContactMechanismTypeID,
			1 AS Valid,
			NULL AS EmailAddressType
		FROM CustomerUpdate.EmailAddress
		WHERE CasePartyCombinationValid = 1
		AND AuditItemID = ParentAuditItemID
		AND ISNULL(ContactMechanismPurposeTypeID, 0) = 0


		-- if the email address change is to add or remove a hyphen, this is not picked up by the checksum matching
		-- add these emails manually
		-- also add an emails that already exist for that party but we are forcing them to become the latest ones
		CREATE TABLE #tmp
		(
			tmpID INT IDENTITY(1, 1) NOT NULL, 
			ContactMechanismID INT, 
			ContactMechanismTypeID TINYINT, 
			EmailAddress NVARCHAR(510),
			CaseID INT,
			PartyID INT,
			EmailIsCurrentForParty INT
		)


		INSERT INTO #tmp
		(
			ContactMechanismID,
			ContactMechanismTypeID,
			EmailAddress,
			CaseID,
			PartyID,
			EmailIsCurrentForParty
		)
		SELECT
			CUEA.ContactMechanismID,
			@EmailPurposeTypeID AS ContactMechanismTypeID,
			CUEA.EmailAddress,
			CUEA.CaseID,
			CUEA.PartyID,
			CUEA.EmailIsCurrentForParty
		FROM CustomerUpdate.EmailAddress CUEA
		LEFT JOIN [$(AuditDB)].Audit.EmailAddresses A ON A.AuditItemID = CUEA.AuditItemID
		WHERE A.AuditItemID IS NULL
		AND CUEA.CasePartyCombinationValid = 1

		DECLARE @max_ContactMechanismID INT
		SELECT @max_ContactMechanismID = MAX(ContactMechanismID) FROM [$(SampleDB)].ContactMechanism.ContactMechanisms

		UPDATE #tmp
		SET ContactMechanismID = tmpID + @max_ContactMechanismID
		WHERE EmailIsCurrentForParty = 0

		INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_ContactMechanisms
		(
			AuditItemID, 
			ContactMechanismID, 
			ContactMechanismTypeID, 
			Valid
		)
		SELECT
			CUEA.AuditItemID,
			T.ContactMechanismID,
			T.ContactMechanismTypeID,
			1 AS Valid
		FROM CustomerUpdate.EmailAddress CUEA
		INNER JOIN #tmp T ON T.EmailAddress = CUEA.EmailAddress
				AND CUEA.CaseID = T.CaseID
				AND CUEA.PartyID = T.PartyID

		INSERT INTO [$(SampleDB)].ContactMechanism.EmailAddresses
		(
			[ContactMechanismID], 
			[EmailAddress]
		)
		SELECT
			ContactMechanismID, 
			EmailAddress
		FROM #tmp
		WHERE EmailIsCurrentForParty = 0 -- ONLY LOAD NON CURRENT EMAILS INTO EmailAddresses
		ORDER BY ContactMechanismID
				
		INSERT INTO [$(AuditDB)].Audit.EmailAddresses
		(
			AuditItemID,
			ContactMechanismID, 
			EmailAddress
		)
		SELECT
			CUEA.AuditItemID,
			T.ContactMechanismID,
			T.EmailAddress
		FROM CustomerUpdate.EmailAddress CUEA
		INNER JOIN #tmp T ON T.EmailAddress = CUEA.EmailAddress
				AND CUEA.CaseID = T.CaseID
				AND CUEA.PartyID = T.PartyID


		-- get the ContactMechanismIDs generated
		UPDATE CUEA
		SET CUEA.ContactMechanismID = ISNULL(AEA.ContactMechanismID, 0)
		FROM CustomerUpdate.EmailAddress CUEA
		LEFT JOIN [$(AuditDB)].Audit.EmailAddresses AEA ON AEA.AuditItemID = CUEA.AuditItemID

		-- get the email types for emails we've matched
		UPDATE CUEA
		SET CUEA.ContactMechanismPurposeTypeID = PCMP.ContactMechanismPurposeTypeID
		FROM CustomerUpdate.EmailAddress CUEA
		INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanismPurposes PCMP ON PCMP.ContactMechanismID = CUEA.ContactMechanismID
										AND PCMP.PartyID = CUEA.PartyID
		INNER JOIN (
			SELECT
				CUEA.CaseID,
				CUEA.PartyID,
				CUEA.ContactMechanismID,
				MAX(PCMP.FromDate) AS MaxFromDate
			FROM CustomerUpdate.EmailAddress CUEA
			INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanismPurposes PCMP ON PCMP.ContactMechanismID = CUEA.ContactMechanismID
											AND PCMP.PartyID = CUEA.PartyID
			GROUP BY CUEA.CaseID,
				CUEA.PartyID,
				CUEA.ContactMechanismID
		) M ON M.CaseID = CUEA.CaseID
			AND M.PartyID = CUEA.PartyID
			AND M.ContactMechanismID = CUEA.ContactMechanismID
			AND M.MaxFromDate = PCMP.FromDate

		-- set all remaining email addresses to e-mail address (unknown purpose)
		UPDATE CustomerUpdate.EmailAddress
		SET ContactMechanismPurposeTypeID = @UnknownEmailPurposeTypeID
		WHERE ISNULL(ContactMechanismPurposeTypeID, 0) = 0

		-- PartyContactMechanisms
		INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_PartyContactMechanisms
		(
			AuditItemID,
			ContactMechanismID,
			PartyID,
			FromDate,
			ContactMechanismPurposeTypeID
		)
		SELECT
			AuditItemID,
			ContactMechanismID,
			PartyID,
			GETDATE(),
			ContactMechanismPurposeTypeID
		FROM CustomerUpdate.EmailAddress
		WHERE CasePartyCombinationValid = 1
		AND AuditItemID = ParentAuditItemID
		AND ISNULL(ContactMechanismID, 0) > 0 


		-- perform the blacklist checking
		INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_BlacklistContactMechanisms
		SELECT DISTINCT
			CUEA.AuditItemID,
			CUEA.ContactMechanismID,
			@EmailPurposeTypeID AS ContactMechanismTypeID,
			S.BlacklistStringID,
			GETDATE() AS FromDate
		FROM CustomerUpdate.EmailAddress CUEA
		INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistStrings S ON CUEA.EmailAddress NOT LIKE S.BlacklistString
		WHERE S.Operator = 'NOT LIKE'
		AND ISNULL(CUEA.ContactMechanismID, 0) > 0 
		AND (GETDATE() BETWEEN S.Fromdate AND ISNULL(ThroughDate, GETDATE())) 

		INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_BlacklistContactMechanisms
		SELECT DISTINCT
			CUEA.AuditItemID,
			CUEA.ContactMechanismID,
			@EmailPurposeTypeID AS ContactMechanismTypeID,
			S.BlacklistStringID,
			GETDATE() AS FromDate
		FROM CustomerUpdate.EmailAddress CUEA
		INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistStrings S ON CUEA.EmailAddress = S.BlacklistString
		WHERE S.Operator = '='
		AND ISNULL(CUEA.ContactMechanismID, 0) > 0 
		AND (GETDATE() BETWEEN S.Fromdate AND ISNULL(ThroughDate, GETDATE())) 

		INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_BlacklistContactMechanisms
		SELECT DISTINCT
			CUEA.AuditItemID,
			CUEA.ContactMechanismID,
			@EmailPurposeTypeID AS ContactMechanismTypeID,
			S.BlacklistStringID,
			GETDATE() AS FromDate
		FROM CustomerUpdate.EmailAddress CUEA
		INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistStrings S ON CUEA.EmailAddress LIKE S.BlacklistString
		WHERE S.Operator = 'LIKE'
		AND ISNULL(CUEA.ContactMechanismID, 0) > 0 
		AND (GETDATE() BETWEEN S.Fromdate AND ISNULL(ThroughDate, GETDATE())) 
	
	COMMIT TRAN


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





