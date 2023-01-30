CREATE PROCEDURE [CustomerUpdate].[uspValidateOutcomeCodes]

		@AuditId		[dbo].[AuditID]

As
		
		IF EXISTS (
						SELECT		* 
						FROM		[CustomerUpdate].[ContactOutcome]			CO
						LEFT JOIN	[$(SampleDB)].[ContactMechanism].[OutcomeCodes]	OC ON CONVERT(VARCHAR,CO.[OutcomeCode]) = OC.[OutcomeCode]

						WHERE		CO.AuditID = @AuditId AND
									OC.OutcomeCode IS NULL			
					)  
			--THERE AERE INVALID OUTCOME CODES IN THE FILE, FAIL THE LOAD
			SELECT CAST(1 AS BIT) AS InvalidOutcomes
		
		ELSE 
			--OUTCOME CODES IN THE FILE ARE VALID 
			SELECT CAST(0 AS BIT) AS InvalidOutcomes