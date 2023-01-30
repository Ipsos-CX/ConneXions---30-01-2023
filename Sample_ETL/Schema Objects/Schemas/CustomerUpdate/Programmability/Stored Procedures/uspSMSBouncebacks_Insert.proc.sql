CREATE PROCEDURE CustomerUpdate.uspSMSBouncebacks_Insert

AS

/*
	Purpose:	Set ContactMechanismNonSolicitation for SMS bounce backs 
	
	Version			Date			Developer			Comment
	1.0				20/01/2013		Chris Ross			Created.

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

		-- Set the Outcomecodes 
		DECLARE @SMSBouncebackOutcomeCode  int
		SELECT @SMSBouncebackOutcomeCode = OutcomeCode FROM [$(SampleDB)].ContactMechanism.OutcomeCodes OC 
													   WHERE Outcome = 'SMS Bounceback'
		UPDATE CustomerUpdate.SMSBouncebacks
		SET OutcomeCode = @SMSBouncebackOutcomeCode


		-- GET THE ContactMechanismID FROM THE Mobile Number SUPPLIED
		-- Note: We are not getting the country prefix so just match on the mobile number
		UPDATE CUSB
		SET CUSB.ContactMechanismID = TN.ContactMechanismID,
			CUSB.CasePartyMobileCombinationValid = 1
		FROM CustomerUpdate.SMSBouncebacks CUSB
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CUSB.CaseID AND AEBI.PartyID = CUSB.PartyID
		INNER JOIN [$(SampleDB)].Event.CaseContactMechanisms CCM ON CCM.CaseID = CUSB.CaseID 
		INNER JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers TN 
								ON TN.ContactMechanismID = CCM.ContactMechanismID
								AND CUSB.MobileNumber like '%' + convert(nvarchar(100), CONVERT(BIGINT,([$(SampleDB)].dbo.udfReturnNumericsOnly(TN.ContactNumber) )))
		WHERE CUSB.DateProcessed IS NULL
		AND CUSB.AuditItemID = CUSB.ParentAuditItemID
		AND ISNULL(CUSB.MobileNumber, '') <> ''



		-- SET ContactMechanismNonSolicitation text
		DECLARE @SMSBounceBackNonSolicitationTextID INT
		SET @SMSBounceBackNonSolicitationTextID = (SELECT NonSolicitationTextID FROM [$(SampleDB)].dbo.NonSolicitationTexts WHERE NonSolicitationText = 'SMS Bounce Back')


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
		SELECT
			CUSB.AuditItemID,
			0 AS NonSolicitationID,
			@SMSBounceBackNonSolicitationTextID AS NonSolicitationTextID,
			CUSB.PartyID,
			@ProcessDate AS FromDate,
			'JLR Customer Update' AS Notes,
			CUSB.ContactMechanismID
		FROM CustomerUpdate.SMSBouncebacks CUSB
		INNER JOIN [$(SampleDB)].ContactMechanism.OutcomeCodes OC ON OC.OutcomeCode = CUSB.OutcomeCode
		WHERE CUSB.DateProcessed IS NULL
		AND ISNULL(CUSB.ContactMechanismID, 0) <> 0
		AND OC.NonSolicitationType = 'ContactMechanism'
		AND CUSB.AuditItemID = CUSB.ParentAuditItemID
		AND CUSB.CasePartyMobileCombinationValid = 1



		-- INSERT THE CaseContactMechanismOutcomes
		INSERT INTO [$(SampleDB)].Event.vwDA_CaseContactMechanismOutcomes
		(
			AuditItemID,
			PartyID,
			CaseID,
			OutcomeCode,
			ContactMechanismID,
			ActionDate,
			MobileNumber,
			CasePartyMobileCombinationValid
		)
		SELECT
			AuditItemID,
			PartyID,
			CaseID,
			OutcomeCode,
			ISNULL(ContactMechanismID, 0) AS ContactMechanismID,
			@ProcessDate AS ActionDate,
			MobileNumber,
			CasePartyMobileCombinationValid
		FROM CustomerUpdate.SMSBouncebacks
		WHERE DateProcessed IS NULL
		AND AuditItemID = ParentAuditItemID

		-- SET THE DateProcessed IN CustomerUpdate.ContactOutcome
		UPDATE CustomerUpdate.SMSBouncebacks
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


