CREATE PROCEDURE [CustomerUpdate].[uspValidateOutcomeCodes]

	@AuditID	[dbo].[AuditID]

AS

/*
		Purpose:	Check Valid Outcome Codes
	
		Version		Date			Developer			Comment
LIVE	1.8			14/09/2022		Chris Ledger		TASK 1032 - Add SP to solution
*/
		
IF EXISTS (	SELECT * 
			FROM CustomerUpdate.ContactOutcome CO
				LEFT JOIN	[$(SampleDB)].ContactMechanism.OutcomeCodes OC ON CONVERT(VARCHAR, CO.OutcomeCode) = OC.OutcomeCode
			WHERE CO.AuditID = @AuditID
				AND OC.OutcomeCode IS NULL)  
	-- THERE AERE INVALID OUTCOME CODES IN THE FILE, FAIL THE LOAD
	SELECT CAST(1 AS BIT) AS InvalidOutcomes
		
ELSE 
	-- OUTCOME CODES IN THE FILE ARE VALID 
	SELECT CAST(0 AS BIT) AS InvalidOutcomes

GO