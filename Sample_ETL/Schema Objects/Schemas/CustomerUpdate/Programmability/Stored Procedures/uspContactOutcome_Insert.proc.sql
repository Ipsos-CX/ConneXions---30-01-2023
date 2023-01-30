CREATE PROCEDURE CustomerUpdate.uspContactOutcome_Insert

AS

/*
		Purpose:	Set a ContactMechanismNonSolicitation for hard email bounce backs or a PartyNonSolicitation for unsubscription requests
	
		Version		Date			Developer			Comment
LIVE	1.0			$(ReleaseDate)	Simon Peacock		Created FROM [Prophet-ETL].dbo.uspIP_CUSTOMERUPDATE_ODSInsert_ContactOutcome
LIVE	1.1			Chris Ross		Chris Ross			BUG 9710 - Email Address not being matched correctly AND hence non-solicitating incorrect one.
LIVE	1.2			16/04/2014		Ali Yuksel			BUG 10248 - Fixed PartyIDs with the duplicate email address, all ContactMechanismIDs of the PartyID with the same email added to the ContactMechanismNonSolicitations
LIVE	1.3			12/02/2015		Chris Ross			BUG 10671 - Add in HardSet flag ON non-solicatations.
LIVE	1.4			30/08/2016		Chris Ross			BUG 12859 - Add in Bounceback AND Unsubscribe for Lost Leads
LIVE	1.5			09/12/2016		Chris Ross			BUG 13364 - Add in Unsubscribes as specific Contact Preferences update.  Use new "Party Non-solicitation" non-sol text instead of "unsubscribe". 
LIVE	1.6			10/07/2017		Chris Ledger		BUG 13997 - Add in Postal Address Non Delivery Handling
LIVE	1.7			10/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
LIVE	1.8			13/09/2022		Chris Ledger		TASK 1032 - Add in check for Medallia Duplicates
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

		DECLARE @ProcessDate DATETIME

		SET @ProcessDate = GETDATE()

		-------------------------------------------------------------------------------------------------------------------
		-- FIRST MOVE TELEPHONE NUMBERS FROM THE EMAIL COLUMN AND SET THE FLAGS TO ZERO							-- V1.4
		-------------------------------------------------------------------------------------------------------------------
		UPDATE CustomerUpdate.ContactOutcome 
		SET TelephoneNumber = '',
			CasePartyCombinationValid = 0,
			CasePartyPhoneCombinationValid = 0


		UPDATE CUCO
		SET TelephoneNumber = EmailAddress,
			EmailAddress = ''
		FROM CustomerUpdate.ContactOutcome CUCO 
		WHERE CUCO.OutcomeCode IN (	SELECT OC.OutcomeCode														-- V1.4
									FROM [$(SampleDB)].ContactMechanism.OutcomeCodes OC
										INNER JOIN [$(SampleDB)].ContactMechanism.OutcomeCodeTypes OCT ON OC.OutcomeCodeTypeID = OCT.OutcomeCodeTypeID
									WHERE OCT.OutcomeCodeType = 'CATI')


		-------------------------------------------------------------------------------------------------------------------
		-- CHECK CASE PARTY EMAIL COMBO CORRECT
		-------------------------------------------------------------------------------------------------------------------
		-- IF WE HAVE BEEN SUPPLIED THE CONTACTMECHANISMID CHECK THIS IT IS VALID FOR THE CASEID AND PARTYID
		UPDATE CUCO
		SET CUCO.CasePartyCombinationValid = 1
		FROM CustomerUpdate.ContactOutcome CUCO
			INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CUCO.CaseID 
																				AND AEBI.PartyID = CUCO.PartyID
			INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON PCM.PartyID = CUCO.PartyID
		WHERE CUCO.DateProcessed IS NULL
			AND CUCO.AuditItemID = CUCO.ParentAuditItemID


		
		-------------------------------------------------------------------------------------------------------------------
		-- CHECK CASE PARTY EMAIL COMBO CORRECT
		-------------------------------------------------------------------------------------------------------------------
		-- IF WE HAVE BEEN SUPPLIED THE CONTACTMECHANISMID CHECK THIS IT IS VALID FOR THE CASEID AND PARTYID
		UPDATE CUCO
		SET CUCO.CasePartyEmailCombinationValid = 1
		FROM CustomerUpdate.ContactOutcome CUCO
			INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CUCO.CaseID 
																				AND AEBI.PartyID = CUCO.PartyID
			INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON PCM.PartyID = CUCO.PartyID
			INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = PCM.ContactMechanismID 
																		AND EA.ContactMechanismID = CUCO.ContactMechanismID
		WHERE CUCO.DateProcessed IS NULL
			AND CUCO.AuditItemID = CUCO.ParentAuditItemID
			AND ISNULL(CUCO.ContactMechanismID, 0) <> 0
			AND CUCO.OutcomeCode IN (	SELECT OC.OutcomeCode													-- V1.4
										FROM [$(SampleDB)].ContactMechanism.OutcomeCodes OC
											INNER JOIN [$(SampleDB)].ContactMechanism.OutcomeCodeTypes OCT ON OC.OutcomeCodeTypeID = OCT.OutcomeCodeTypeID
										WHERE OCT.OutcomeCodeType = 'Online')


		-- IF WE'VE NOT BEEN SUPPLIED THE CONTACTMECHANISMID GET IT FROM THE EMAIL SUPPLIED
		UPDATE CUCO
		SET CUCO.ContactMechanismID = EA.ContactMechanismID,
			CUCO.CasePartyEmailCombinationValid = 1
		FROM CustomerUpdate.ContactOutcome CUCO
			INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CUCO.CaseID AND AEBI.PartyID = CUCO.PartyID
			INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON PCM.PartyID = CUCO.PartyID
			INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = PCM.ContactMechanismID
																			AND EA.EmailAddress = CUCO.EmailAddress					-- V1.1
		WHERE CUCO.DateProcessed IS NULL
			AND CUCO.AuditItemID = CUCO.ParentAuditItemID
			AND ISNULL(CUCO.ContactMechanismID, 0) = 0
			AND CUCO.OutcomeCode IN (	SELECT OC.OutcomeCode 													-- V1.4
										FROM [$(SampleDB)].ContactMechanism.OutcomeCodes OC
											INNER JOIN [$(SampleDB)].ContactMechanism.OutcomeCodeTypes OCT ON OC.OutcomeCodeTypeID = OCT.OutcomeCodeTypeID
										WHERE OCT.OutcomeCodeType = 'Online')

		
		-------------------------------------------------------------------------------------------------------------------
		-- CHECK CASE PARTY TELEPHONE COMBO CORRECT
		-------------------------------------------------------------------------------------------------------------------
		-- IF WE'VE NOT BEEN SUPPLIED THE CONTACTMECHANISMID GET IT FROM THE PHONE NUMBER SUPPLIED
		UPDATE CUCO
		SET CUCO.CasePartyPhoneCombinationValid = 1
		FROM CustomerUpdate.ContactOutcome CUCO
			INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CUCO.CaseID 
																				AND AEBI.PartyID = CUCO.PartyID
		WHERE CUCO.DateProcessed IS NULL
			AND CUCO.AuditItemID = CUCO.ParentAuditItemID
			AND ISNULL(CUCO.ContactMechanismID, 0) = 0
			AND CUCO.OutcomeCode IN (	SELECT OC.OutcomeCode 													-- V1.4
										FROM  [$(SampleDB)].ContactMechanism.OutcomeCodes OC
											INNER JOIN [$(SampleDB)].ContactMechanism.OutcomeCodeTypes OCT ON OC.OutcomeCodeTypeID = OCT.OutcomeCodeTypeID
										WHERE OCT.OutcomeCodeType = 'CATI')						


		--------------------------------------------------------------------------------------------------------------
		-- V1.6 CHECK CASE PARTY ADDRESS COMBO CORRECT
		-- WE WILL NOT RECEIVE ANY ADDRESSES OR CONTACTMECHANISM IDS SO NO CODE ADDED HERE
		--------------------------------------------------------------------------------------------------------------


		-------------------------------------------------------------------------------------------------------------------
		-- V1.8 CHECK FOR DUPLICATE MEDALLIA RECORDS
		-------------------------------------------------------------------------------------------------------------------
		UPDATE CUCO
		SET CUCO.MedalliaDuplicate = 1
		FROM CustomerUpdate.ContactOutcome CUCO
			INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_ContactOutcome ACUCO ON CUCO.CaseID = ACUCO.CaseID
																				AND CUCO.OutcomeCode = ACUCO.OutcomeCode

	
		--------------------------------------------------------------------------------------------------------------
		-- PROCESS OUTCOME CODES
		--------------------------------------------------------------------------------------------------------------

		-- SET CONTACTMECHANISMNONSOLICITATION FOR HARD EMAIL BOUNCE BACK
		DECLARE @EmailBounceBackNonSolicitationTextID INT
		DECLARE @PartyNonSolicitationTextID INT										-- V1.5
		DECLARE @TelephoneBounceBackNonSolicitationTextID INT						-- V1.4
		DECLARE @PostalNonDeliveryNonSolicitationTextID INT							-- V1.6

		SET @EmailBounceBackNonSolicitationTextID = (SELECT NonSolicitationTextID FROM [$(SampleDB)].dbo.NonSolicitationTexts WHERE NonSolicitationText = 'Email Bounce Back')
		SET @TelephoneBounceBackNonSolicitationTextID = (SELECT NonSolicitationTextID FROM [$(SampleDB)].dbo.NonSolicitationTexts WHERE NonSolicitationText = 'Telephone Bounce Back')	-- V1.4
		SET @PostalNonDeliveryNonSolicitationTextID = (SELECT NonSolicitationTextID FROM [$(SampleDB)].dbo.NonSolicitationTexts WHERE NonSolicitationText = 'Undelivered')				-- V1.6
		SET @PartyNonSolicitationTextID = (SELECT NonSolicitationTextID FROM [$(SampleDB)].dbo.NonSolicitationTexts WHERE NonSolicitationText = 'Party Non-solicitation')				-- V1.5


		--- CONTACT MECHANISM NON-SOLICITATIONS ---
		INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_ContactMechanismNonSolicitations
		(
			AuditItemID,
			NonSolicitationID,
			NonSolicitationTextID,
			PartyID,
			FromDate,
			Notes,
			ContactMechanismID
		)
		SELECT DISTINCT 
				CUCO.AuditItemID,
				0 AS NonSolicitationID,
				@EmailBounceBackNonSolicitationTextID AS NonSolicitationTextID,
				CUCO.PartyID,
				@ProcessDate AS FromDate,
				'JLR Customer Update' AS Notes,
				--CUCO.ContactMechanismID
				PCM.ContactMechanismID
			FROM CustomerUpdate.ContactOutcome CUCO
				INNER JOIN [$(SampleDB)].ContactMechanism.OutcomeCodes OC ON OC.OutcomeCode = CUCO.OutcomeCode
				INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON PCM.PartyID=CUCO.PartyID			-- V1.2 
				INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID=PCM.ContactMechanismID 
																			AND EA.EmailAddress=CUCO.EmailAddress
				WHERE CUCO.DateProcessed IS NULL
					AND ISNULL(CUCO.ContactMechanismID, 0) <> 0
					AND OC.NonSolicitationType = 'ContactMechanism'
					AND CUCO.AuditItemID = CUCO.ParentAuditItemID
					AND CUCO.CasePartyEmailCombinationValid = 1
					AND CUCO.MedalliaDuplicate = 0								-- V1.9
		UNION
			SELECT DISTINCT 
				CUCO.AuditItemID,
				0 AS NonSolicitationID,
				@TelephoneBounceBackNonSolicitationTextID AS NonSolicitationTextID,
				CUCO.PartyID,
				@ProcessDate AS FromDate,
				'JLR Customer Update' AS Notes,
				--CUCO.ContactMechanismID
				TN.ContactMechanismID
			FROM CustomerUpdate.ContactOutcome CUCO
				INNER JOIN [$(SampleDB)].ContactMechanism.OutcomeCodes OC ON OC.OutcomeCode = CUCO.OutcomeCode
				INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON PCM.PartyID=CUCO.PartyID		-- V1.2 
				--INNER JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers EA ON EA.ContactMechanismID=PCM.ContactMechanismID AND EA.ContactNumber = CUCO.TelephoneNumber
				INNER JOIN [$(SampleDB)].Event.CaseContactMechanisms CCM ON CUCO.CaseID = CCM.CaseID
				INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypes CT ON CCM.ContactMechanismTypeID = CT.ContactMechanismTypeID 
																					AND CT.ContactMechanismType IN ('Phone','Phone (landline)','Phone (mobile)')
				INNER JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers TN ON CCM.ContactMechanismID = TN.ContactMechanismID					
			WHERE CUCO.DateProcessed IS NULL
				AND OC.NonSolicitationType = 'ContactMechanism'
				AND CUCO.AuditItemID = CUCO.ParentAuditItemID
				AND CUCO.CasePartyPhoneCombinationValid = 1
				AND CUCO.MedalliaDuplicate = 0								-- V1.9
		--------------------------------------------------------------------------------------------------------------
		-- V1.6 ADD PARTY ADDRESS COMBO
		--------------------------------------------------------------------------------------------------------------
		UNION
			SELECT DISTINCT 
				CUCO.AuditItemID,
				0 AS NonSolicitationID,
				@PostalNonDeliveryNonSolicitationTextID AS NonSolicitationTextID,
				CUCO.PartyID,
				@ProcessDate AS FromDate,
				'JLR Customer Update' AS Notes,
				PA.ContactMechanismID
			FROM CustomerUpdate.ContactOutcome CUCO
				INNER JOIN [$(SampleDB)].ContactMechanism.OutcomeCodes OC ON OC.OutcomeCode = CUCO.OutcomeCode
				INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON PCM.PartyID = CUCO.PartyID 
				INNER JOIN [$(SampleDB)].Event.CaseContactMechanisms CCM ON CUCO.CaseID = CCM.CaseID
				INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypes CT ON CCM.ContactMechanismTypeID = CT.ContactMechanismTypeID 
																					AND CT.ContactMechanismType IN ('Postal Address')
				INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON CCM.ContactMechanismID = PA.ContactMechanismID
			WHERE CUCO.DateProcessed IS NULL
				AND OC.NonSolicitationType = 'ContactMechanism'
				AND CUCO.AuditItemID = CUCO.ParentAuditItemID
				AND CUCO.CasePartyCombinationValid = 1
				AND CUCO.OutcomeCode IN (	SELECT OC.OutcomeCode 
											FROM [$(SampleDB)].ContactMechanism.OutcomeCodes OC
												INNER JOIN [$(SampleDB)].ContactMechanism.OutcomeCodeTypes OCT ON OC.OutcomeCodeTypeID = OCT.OutcomeCodeTypeID
											WHERE OCT.OutcomeCodeType = 'Paper')
				AND CUCO.MedalliaDuplicate = 0								-- V1.9


		---- PARTY NON-SOLICITATIONS ---
		INSERT INTO [$(SampleDB)].Party.vwDA_NonSolicitations
		(
			AuditItemID,
			NonSolicitationID,
			NonSolicitationTextID,
			PartyID,
			FromDate,
			Notes
		)
		SELECT
			CUCO.AuditItemID,
			0 AS NonSolicitationID,
			@PartyNonSolicitationTextID AS NonSolicitationTextID,			-- V1.5
			CUCO.PartyID,
			@ProcessDate AS FromDate,
			'JLR Customer Update' AS Notes
		FROM CustomerUpdate.ContactOutcome CUCO
			INNER JOIN [$(SampleDB)].ContactMechanism.OutcomeCodes OC ON OC.OutcomeCode = CUCO.OutcomeCode
		WHERE CUCO.DateProcessed IS NULL
			AND OC.NonSolicitationType = 'Party'
			AND CUCO.AuditItemID = CUCO.ParentAuditItemID
			AND CUCO.CasePartyCombinationValid = 1
			AND CUCO.MedalliaDuplicate = 0									-- V1.9


		-- SET CONTACT PREFERENCES FOR UNSUBSCRIPTION REQUEST ---			-- V1.5
		INSERT INTO [$(SampleDB)].Party.vwDA_ContactPreferences 
		(
			AuditItemID,
			PartyID,
			EventCategoryID,
			PartyUnsubscribe,
			UpdateSource,
			MarketCountryID
		)
		SELECT
			CUCO.AuditItemID,
			CUCO.PartyID,
			ETC.EventCategoryID,
			1 AS PartyUnsubscribe,
			'Customer Update' AS UpdateSource,
			CD.CountryID As MarketCountryID
		FROM CustomerUpdate.ContactOutcome CUCO
			INNER JOIN [$(SampleDB)].ContactMechanism.OutcomeCodes OC ON OC.OutcomeCode = CUCO.OutcomeCode
			INNER JOIN [$(SampleDB)].Meta.CaseDetails CD ON CD.CaseID = CUCO.CaseID
			INNER JOIN [$(SampleDB)].Event.EventTypeCategories ETC ON ETC.EventTypeID = CD.EventTypeID
		WHERE CUCO.DateProcessed IS NULL
			AND OC.Unsubscribe = 1
			AND CUCO.AuditItemID = CUCO.ParentAuditItemID
			AND CUCO.CasePartyCombinationValid = 1
			AND CUCO.MedalliaDuplicate = 0									-- V1.9


		-- INSERT THE CASECONTACTMECHANISMOUTCOMES ---		
		INSERT INTO [$(SampleDB)].Event.vwDA_CaseContactMechanismOutcomes
		(
			AuditItemID,
			PartyID,
			CaseID,
			OutcomeCode,
			ContactMechanismID,
			EmailAddress,
			ActionDate,
			CasePartyEmailCombinationValid,
			TelephoneNumber,    
			CasePartyPhoneCombinationValid,
			CasePartyCombinationValid
		)
		SELECT DISTINCT
			AuditItemID,
			CUCO.PartyID,
			CaseID,
			OutcomeCode,
			ISNULL(CUCO.ContactMechanismID, 0) AS ContactMechanismID,			
			CUCO.EmailAddress,
			@ProcessDate AS ActionDate,
			CasePartyEmailCombinationValid,
			TelephoneNumber,							-- V1.4
			CasePartyPhoneCombinationValid,				-- V1.4
			CasePartyCombinationValid					-- V1.4
		FROM CustomerUpdate.ContactOutcome CUCO
			-- V1.4 Comment out  -- V1.2
			--INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON PCM.PartyID=CUCO.PartyID 
			--INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID=PCM.ContactMechanismID AND EA.EmailAddress=CUCO.EmailAddress
		WHERE DateProcessed IS NULL
			AND AuditItemID = ParentAuditItemID
			AND CUCO.CasePartyCombinationValid = 1							-- V1.4 
			AND CUCO.MedalliaDuplicate = 0									-- V1.9

			
		-- SET THE DateProcessed IN CustomerUpdate.ContactOutcome
		UPDATE CustomerUpdate.ContactOutcome
		SET DateProcessed = @ProcessDate
		WHERE DateProcessed IS NULL


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


