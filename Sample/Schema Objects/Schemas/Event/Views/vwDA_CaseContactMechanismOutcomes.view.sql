

CREATE VIEW Event.vwDA_CaseContactMechanismOutcomes

AS

/*
	Version		Date		Developer		Comment
	1.0		09/07/2009		Simon Peacock	Created
	1.1		31/08/2016		Chris Ross		12859 - Add in new columns: CasePartyCombinationValid and CasePartyPhoneCombinationValid and TelephoneNumber
*/

SELECT
 	CONVERT(BIGINT, 0)			AS AuditItemID, 
	CaseID,
	CONVERT(BIGINT, 0)			AS PartyID, 
	OutcomeCode,
	CONVERT(INT, 0)				AS OutcomeCodeTypeID,
	ContactmechanismID,
	CONVERT(NVARCHAR(510), '')	AS EmailAddress,
	ActionDate,
	CONVERT(BIT, 0)				AS CasePartyEmailCombinationValid,
	CONVERT(NVARCHAR(70), '')	AS MobileNumber,
	CONVERT(BIT, 0)				AS CasePartyMobileCombinationValid,
	CONVERT(NVARCHAR(70), '')	AS TelephoneNumber,    
	CONVERT(BIT, 0)				AS CasePartyPhoneCombinationValid,
    CONVERT(BIT, 0)				AS CasePartyCombinationValid
FROM Event.CaseContactMechanismOutcomes


