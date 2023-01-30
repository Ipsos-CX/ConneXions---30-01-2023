CREATE PROCEDURE CRM.uspSC114SetOutputDatesForBatch 
	@Batch	INT, 
	@FileName VARCHAR(1000)
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
		Purpose:	Set the output dates in the CRM.LostLeadResponseStatuses table 
					for the CasesIDs in an output batch
		
		Version		Date				Developer			Comment
LIVE	1.0			2021-12-14			Chris Ledger		Created
*/


	BEGIN TRAN 
	
		--------------------------------------------------------------------------------------------------
		-- Get single date for entire batch
		--------------------------------------------------------------------------------------------------
		DECLARE @DateTime DATETIME2
		SET @DateTime = GETDATE()


		--------------------------------------------------------------------------------------------------
		-- Set output date on the Response Status recs in the batch				
		--------------------------------------------------------------------------------------------------
		UPDATE RS
		SET RS.OutputToCRMDate = @DateTime
		FROM CRM.OutputBatches B 
		INNER JOIN CRM.LostLeadResponseStatuses RS ON RS.CaseID = B.CaseID
												  AND RS.EventID = B.EventID
												  AND RS.OutputToCRMDate IS NULL
		WHERE B.Batch = @Batch


		--------------------------------------------------------------------------------------------------
		-- Save the UUID updated records to Audit so that we can track mutiple outputs (should they happen)
		-- As we are only outputting each Case/event once per file we will only output one audit record 
		--------------------------------------------------------------------------------------------------
		INSERT INTO [$(AuditDB)].Audit.CRMSC114Outputs (CaseID, EventID, LoadedToConnexions, UUID, OutputFileName, OutputToCRMDate, ResponseStatusID)
		SELECT DISTINCT
			B.CaseID, 
			B.EventID,
			B.LoadToConnexionsDate, 
			RS.UUID, 
			@FileName AS OutputFileName,
			RS.OutputToCRMDate,
			B.OutputResponseStatusID
		FROM CRM.OutputBatches B 
			LEFT JOIN CRM.LostLeadResponseStatuses RS ON RS.CaseID = B.CaseID
														AND RS.EventID = B.EventID
														AND RS.ResponseStatusID = B.OutputResponseStatusID
														AND RS.OutputToCRMDate = @DateTime
		WHERE B.Batch = @Batch


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