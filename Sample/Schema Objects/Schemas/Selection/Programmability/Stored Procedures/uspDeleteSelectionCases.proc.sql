CREATE PROCEDURE [Selection].[uspDeleteSelectionCases]

	@SelectionRequirementID INT

AS

/*
		Purpose:	Delete Selections 
		
		Version		Date			Developer			Comment
LIVE	1.8			2017-03-28		Chris Ledger		Bug 13775 - Delete CaseID from Meta.CaseDetails table
LIVE	1.9			2017-04-07		Chris Ledger		Fix error in Delete CaseID code
LIVE	1.10		2018-08-03		Chris Ross			BUG 13364 - Add in reset of suppressions non-selection flags. 
LIVE	1.11		2018-04-11		Ben King			BUG 14635 - Retain Selection Rollbacks CaseId's
LIVE	1.12		2018-05-18		Chris Ross			BUG 14776 - Add in missing logging table columns so that we can run as part of Lost Leads reversal.
																    Plus add BEGIN TRAN and COMMIT to stop partial updates.
																    Also, include removal of CaseContactOutcomeMechanism records created by Online Expiry time being hit.
LIVE	1.13		2022-02-11		Chris Ledger		Tidy formatting
*/

-- ROLLBACK ON ERROR	
SET XACT_ABORT ON
-- DISABLE COUNTS
SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

/* IDENTIFY CASES IN SELECTION, BASED ON THE @SelectionRequirementID */
DECLARE @tmpCases TABLE
(
	CaseID INT,	
	UNIQUE(CaseID)
)

BEGIN TRY

	BEGIN TRAN 

		INSERT INTO @tmpCases (CaseID)
		SELECT SC.CaseID
		FROM Requirement.SelectionCases SC
		WHERE SC.RequirementIDPartOf = @SelectionRequirementID

		/* UPDATE ELIGIBLE RECORD TARGETS TO SELECTION */
		UPDATE SA
		SET	SA.PostalTarget = SA.PostalTarget + SelCount
		FROM Requirement.SelectionAllocations SA 
			INNER JOIN	(	SELECT RequirementIDPartOf, 
								RequirementIDMadeUpOf, 
								COUNT(*) AS SelCount
							FROM Requirement.SelectionCases
							WHERE RequirementIDPartOf = @SelectionRequirementID
							GROUP BY RequirementIDPartOf, 
								RequirementIDMadeUpOf) D ON SA.RequirementIDPartOf = D.RequirementIDPartOf 
															AND SA.RequirementIDMadeUpOf = D.RequirementIDMadeUpOf
		WHERE SA.RequirementIDPartOf = @SelectionRequirementID
	
	
		UPDATE SA
		SET	SA.EmailTarget = SA.EmailTarget + SelCount
		FROM Requirement.SelectionAllocations SA 
			INNER JOIN (	SELECT RequirementIDPartOf, 
								RequirementIDMadeUpOf, 
								COUNT(*) AS SelCount
							FROM Requirement.SelectionCases
							WHERE RequirementIDPartOf = @SelectionRequirementID
							GROUP BY RequirementIDPartOf, 
								RequirementIDMadeUpOf) D ON SA.RequirementIDPartOf = D.RequirementIDPartOf 
															AND SA.RequirementIDMadeUpOf = D.RequirementIDMadeUpOf
		WHERE SA.RequirementIDPartOf = @SelectionRequirementID

			
		UPDATE SA
		SET	SA.PhoneTarget = SA.PhoneTarget + SelCount
		FROM Requirement.SelectionAllocations SA
			INNER JOIN (	SELECT RequirementIDPartOf, 
								RequirementIDMadeUpOf, 
								COUNT(*) SelCount
							FROM Requirement.SelectionCases
							WHERE RequirementIDPartOf = @SelectionRequirementID
							GROUP BY RequirementIDPartOf, 
								RequirementIDMadeUpOf) D ON SA.RequirementIDPartOf = D.RequirementIDPartOf 
															AND SA.RequirementIDMadeUpOf = D.RequirementIDMadeUpOf
		WHERE SA.RequirementIDPartOf = @SelectionRequirementID


		/* DELETE SELECTED CASES USING @tmpCases */
		DELETE FROM AEBI
		FROM Event.AutomotiveEventBasedInterviews AEBI
			INNER JOIN @tmpCases C ON AEBI.CaseID = C.CaseID


		/* DELETE SELECTED CASES USING @tmpCases */
		DELETE FROM SC
		FROM Requirement.SelectionCases SC
			INNER JOIN @tmpCases C ON SC.CaseID = C.CaseID


		/* DELETE SELECTED CASES USING @tmpCases */
		DELETE FROM CCMO 
		FROM Event.CaseContactMechanismOutcomes CCMO
		INNER JOIN @tmpCases C ON CCMO.CaseID = C.CaseID
		WHERE CCMO.OutcomeCode = 120  -- On-line expiry re-output 


		/* DELETE SELECTED CASES USING @tmpCases */
		DELETE FROM CCM
		FROM Event.CaseContactMechanisms CCM
			INNER JOIN @tmpCases C ON CCM.CaseID = C.CaseID


		/* DELETE SELECTED CASES USING @tmpCases */
		DELETE FROM CR
		FROM Event.CaseRejections CR
			INNER JOIN @tmpCases C ON CR.CaseID = C.CaseID


		/* DELETE SELECTED CASES USING @tmpCases */
		DELETE FROM CO
		FROM Event.CaseOutput CO
			INNER JOIN @tmpCases C ON C.CaseID = CO.CaseID


		/* DELETE SELECTED CASES USING @tmpCases */
		DELETE FROM CS
		FROM Event.Cases CS
			INNER JOIN @tmpCases C ON CS.CaseID = C.CaseID


		/* DELETE SELECTED CASES USING @tmpCases */
		DELETE FROM CD								-- V1.9
		FROM Meta.CaseDetails CD
			INNER JOIN @tmpCases C ON CD.CaseID = C.CaseID
				

		/* DELETE SELECTED CASES USING @tmpCases */
		DELETE FROM CR
		FROM [$(AuditDB)].Audit.CaseRejections CR
			INNER JOIN @tmpCases C ON CR.CaseID = C.CaseID


		/* RESET THE LOGGING TABLES */
		UPDATE SL
		SET SL.CaseID = NULL,
			SL.RecontactPeriod = 0,
			SL.RelativeRecontactPeriod = 0,
			SL.CaseIDPrevious = 0,			
			SL.EventAlreadySelected = 0,
			SL.ExclusionListMatch = 0,
			SL.EventNonSolicitation = 0,
			SL.BarredEmailAddress = 0,
			SL.WrongEventType = 0,
			SL.MissingStreet = 0,
			SL.MissingPostcode = 0,
			SL.MissingEmail = 0,
			SL.MissingTelephone = 0,
			SL.MissingStreetAndEmail = 0,
			SL.MissingTelephoneAndEmail = 0,
			SL.MissingMobilePhone = 0,
			SL.MissingMobilePhoneAndEmail = 0,
			SL.InvalidModel = 0,
			SL.InvalidVariant = 0, 
			SL.MissingPartyName = 0,
			SL.MissingLanguage = 0,
			SL.InternalDealer = 0,
			SL.InvalidOwnershipCycle = 0,
			SL.InvalidRoleType = 0,
			SL.InvalidSaleType = 0,
			SL.InvalidAFRLCode = 0,
			SL.SuppliedAFRLCode = 0,
			SL.DealerExclusionListMatch = 0,
			SL.InvalidCRMSaleType = 0,
			SL.ContactPreferencesSuppression = 0,		-- V1.10
			SL.ContactPreferencesPartySuppress = 0,		-- V1.10
			SL.ContactPreferencesEmailSuppress = 0,		-- V1.10
			SL.ContactPreferencesPhoneSuppress = 0,		-- V1.10
			SL.ContactPreferencesPostalSuppress = 0,	-- V1.10
			SL.MissingLostLeadAgency = 0,				-- V1.11
			SL.PDIFlagSet = 0,							-- V1.11
			SL.ContactPreferencesUnsubscribed = 0,		-- V1.11
			SL.SelectionOrganisationID = NULL,			-- V1.11
			SL.SelectionPostalID = NULL,				-- V1.11
			SL.SelectionEmailID = NULL,					-- V1.11
			SL.SelectionPhoneID	= NULL,					-- V1.11
			SL.SelectionLandlineID = NULL,				-- V1.11
			SL.SelectionMobileID = NULL,				-- V1.11
			SL.SampleRowProcessed = 1,
			SL.SampleRowProcessedDate = GETDATE()	 
		FROM @tmpCases TC
			INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = TC.CaseID


		/* UPDATE SELECTIONREQUIREMENTS DETAILS */
		UPDATE SR
		SET	SR.SelectionStatusTypeID = 1,
			SR.DateLastRun = NULL,
			SR.RecordsSelected = NULL,
			SR.RecordsRejected = NULL,
			SR.DateOutputAuthorised = NULL,
			SR.AuthorisingPartyID = NULL,
			SR.AuthorisingRoleTypeID = NULL,
			SR.ScheduledRunDate = NULL
		FROM Requirement.SelectionRequirements SR
		WHERE SR.RequirementID = @SelectionRequirementID


		--V1.11
		INSERT INTO	Event.CasesRollBack (CaseID, SelectionRequirementID)
		SELECT CaseID, 
			@SelectionRequirementID
		FROM @tmpCases


	COMMIT 


END TRY
BEGIN CATCH

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