CREATE PROCEDURE [CRM].[uspSetOutputDatesForBatch] 
	@Batch	INT, @Filename VARCHAR(1000)
AS 
SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY


/*
	Purpose:	Set the output dates in the Sample.Event.CaseCRM table 
				for the CasesIDs in an output batch
		
	Version		Date				Developer			Comment
	1.0			20/08/2015			Chris Ross			Created
	1.1			05/07/2016			Chris Ross			BUG 12777 - Updated to set Output dates on CaseCRMUnsubscribes as well
	1.2			12/07/2016			Chris Ross			BUG 12777 - Updated to set Output dates on CaseCRMBouncebacks as well
	1.3			05/04/2017			Chris Ross			BUG 13566 - Add in update of CRM.CaseResponseStatuses and add additional info columns to Audit.     
		
*/


	BEGIN TRAN 
	
		--------------------------------------------------------------------------------------------------
		-- Get single date for entire batch
		--------------------------------------------------------------------------------------------------
		DECLARE @Datetime DATETIME2
		SET @Datetime = GETDATE()



		--------------------------------------------------------------------------------------------------
		-- Set output date on the cases and responses in the batch
		--------------------------------------------------------------------------------------------------
		UPDATE c
		SET c.OutputToCRMDate = @Datetime
		FROM CRM.OutputBatches b 
		INNER JOIN [$(SampleDB)].Event.CaseCRM c ON c.CaseID = b.CaseID
												AND c.OutputToCRMDate IS NULL
		WHERE b.Batch = @Batch


		UPDATE cr
		SET cr.OutputToCRMDate = @Datetime
		FROM CRM.OutputBatches b 
		INNER JOIN [$(SampleDB)].Event.CaseCRMResponses cr ON cr.CaseID = b.CaseID
														AND cr.OutputToCRMDate IS NULL
		WHERE b.Batch = @Batch


		--------------------------------------------------------------------------------------------------
		-- Set output date on the Response Status recs in the batch				
		--------------------------------------------------------------------------------------------------

		UPDATE cr
		SET cr.OutputToCRMDate = @Datetime
		FROM CRM.OutputBatches b 
		INNER JOIN [CRM].[CaseResponseStatuses] cr ON cr.CaseID = b.CaseID
												  AND cr.EventID = b.EventID
												  AND cr.OutputToCRMDate IS NULL
		WHERE b.Batch = @Batch



		--------------------------------------------------------------------------------------------------
		-- Save the UUID updated records to Audit so that we can track mutiple outputs (should they happen)
		-- As we are only outputting each Case/event once per file we will only output one audit record 
		--------------------------------------------------------------------------------------------------
		;WITH CTE_CombinedStatuses
		AS (
			SELECT 
			   b.CaseID,
			   b.EventID,
			   STUFF((SELECT '; ' + CAST(u.ResponseStatusID AS VARCHAR(3))
					  FROM CRM.CaseResponseStatuses  u
					  WHERE u.CaseID = b.CaseID 
						AND u.EventID = b.EventID
						AND u.OutputToCRMDate = @Datetime   -- Only include statuses that were output as part of this run
					  FOR XML PATH('')), 1, 1, '') AllStatuses
			FROM  CRM.OutputBatches b WHERE b.Batch = @Batch
			GROUP BY b.CaseID, b.EventID
		)
		INSERT INTO [$(AuditDB)].Audit.CaseCRM_Outputs (CaseID, EventID, ResponseDate, RedFlag, GoldFlag, Unsubscribe, Bounceback, LoadedToConnexions, UUID, 
														 OutputFileName, OutputToCRMDate, ResponseStatusID, AllResponseStatuses)
		SELECT DISTINCT
				b.CaseID, 
				b.EventID,
				c.ResponseDate, 
				c.RedFlag, 
				c.GoldFlag, 
				Unsubscribe,
				Bounceback,
				[LoadToConnexionsDate], 
				rs.UUID, 
				@Filename,
				rs.OutputToCRMDate,
				b.OutputResponseStatusID,
				cs.AllStatuses
		FROM CRM.OutputBatches b 
		LEFT JOIN CTE_CombinedStatuses cs	   ON cs.CaseID = b.CaseID
											  AND cs.EventID = b.EventID
		LEFT JOIN  CRM.CaseResponseStatuses rs ON rs.CaseID = b.CaseID
											  AND rs.EventID = b.EventID
										      AND rs.ResponseStatusID = b.OutputResponseStatusID
											  AND rs.OutputToCRMDate = @Datetime
		LEFT JOIN [$(SampleDB)].Event.CaseCRM c ON c.CaseID = b.CaseID
										   AND c.OutputToCRMDate = @Datetime
		WHERE b.Batch = @Batch


	COMMIT

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