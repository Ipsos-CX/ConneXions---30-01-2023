CREATE TRIGGER Event.TR_I_vwDA_CaseContactMechanismOutcomes ON Event.vwDA_CaseContactMechanismOutcomes
INSTEAD OF INSERT

AS

/*
	Purpose:	Takes care of auditing inserts to CaseContactMechanismOutcomes from customer update files
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_CaseContactMechanismOutcomes.TR_I_vwDA_CaseContactMechanismOutcomes
	1.1				20/01/2014		Chris Ross			BUG 9500  - Add in SMS bounceback fields for auditing
	1.2				31/08/2016		Chris Ross			bug 12859 - Add in new columns: CasePartyCombinationValid and CasePartyPhoneCombinationValid and TelephoneNumber
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	INSERT INTO Event.CaseContactMechanismOutcomes
	(
		CaseID, 
		OutcomeCode,
		OutcomeCodeTypeID,
		ContactMechanismID,
		ActionDate
	)
	SELECT
		I.CaseID, 
		I.OutcomeCode,
		OC.OutcomeCodeTypeID,
		I.ContactMechanismID,
		I.ActionDate
	FROM INSERTED I
	INNER JOIN ContactMechanism.OutcomeCodes OC ON OC.OutcomeCode = I.OutcomeCode
	WHERE ISNULL(I.CasePartyCombinationValid, 0)  = 1				--v1.2
		OR ISNULL(I.CasePartyEmailCombinationValid, 0) = 1			--v1.2
		OR ISNULL(I.CasePartyPhoneCombinationValid, 0) = 1			--v1.2


	INSERT INTO [$(AuditDB)].Audit.CaseContactMechanismOutcomes
	(
		AuditItemID,
		CaseID, 
		PartyID,
		OutcomeCode,
		OutcomeCodeTypeID,
		ContactMechanismID,
		EmailAddress,
		ActionDate,
		CasePartyEmailCombinationValid,
		MobileNumber,
		CasePartyMobileCombinationValid,
		TelephoneNumber,    
		CasePartyPhoneCombinationValid,
		CasePartyCombinationValid
	)
	SELECT
		I.AuditItemID,
 		I.CaseID, 
		I.PartyID,
 		I.OutcomeCode,
 		OC.OutcomeCodeTypeID,
 		I.ContactMechanismID,
		I.EmailAddress,
 		I.ActionDate,
		I.CasePartyEmailCombinationValid,
		I.MobileNumber,
		I.CasePartyMobileCombinationValid,
		I.TelephoneNumber,    
		I.CasePartyPhoneCombinationValid,
		I.CasePartyCombinationValid

	FROM INSERTED I
	INNER JOIN ContactMechanism.OutcomeCodes OC ON OC.OutcomeCode = I.OutcomeCode

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


