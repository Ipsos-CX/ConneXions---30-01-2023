CREATE PROCEDURE CRM.uspSC114CalculateResponseStatuses 
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
		Purpose:	Calculate Response Statuses and add them to the CRM.LostLeadResponseStatuses table (for output to CRM)
		
		Version		Date				Developer			Comment
LIVE	1.0			2021-12-08			Chris Ledger		Created
LIVE	1.1			2022-05-23			Chris Ledger		Task 530 - add CaseID JOIN and LoadedDate filter so only cases created after 2022-05-23 added 
*/

	BEGIN TRAN 
	
		------------------------------------------------------------
		-- Set a single date for load
		------------------------------------------------------------
		DECLARE @DateAddedForOutput DATETIME2
		SET @DateAddedForOutput = GETDATE()
		

		------------------------------------------------------------
		-- Insert Survey Completed
		------------------------------------------------------------

		-- Insert Completed Events
		DECLARE @CompletedStatusID INT
		SELECT @CompletedStatusID = ResponseStatusID FROM CRM.ResponseStatuses WHERE ResponseStatus = 'Completed'
			
		INSERT INTO CRM.LostLeadResponseStatuses (CaseID, EventID, ResponseStatusID, LoadedToConnexions, DateAddedForOutput, AddedByProcess)
		SELECT AEBI.CaseID, 
			E.EventID, 
			@CompletedStatusID AS ResponseStatusID, 
			MIN(F.ActionDate) AS LoadedToConnexions, 
			@DateAddedForOutput AS DateAddedForOutput,
			'CRM.uspSC114CalculateResponseStatuses' AS AddedByProcess
		FROM [$(SampleDB)].Event.Events E
			INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON E.EventID = AEBI.EventID
			INNER JOIN [$(SampleDB)].Event.CRMLostLeadResponses R ON E.EventID = R.EventID
			INNER JOIN [$(AuditDB)].Audit.CRMLostLeadResponses AR ON R.EventID = AR.EventID
			INNER JOIN [$(AuditDB)].dbo.AuditItems AI ON AR.AuditItemID = AI.AuditItemID
			INNER JOIN [$(AuditDB)].dbo.Files F ON AI.AuditID = F.AuditID
			INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.MatchedODSEventID = E.EventID
																						AND SL.CaseID = AEBI.CaseID			-- V1.1
			INNER JOIN CRM.vwValidResponseMarketQuestionnaires BMQ ON BMQ.Market = SL.Market 
																	AND BMQ.EventCategory = SL.Questionnaire
		WHERE SL.LoadedDate >= BMQ.FromDate
			AND SL.LoadedDate >= '2022-05-21'																				-- V1.1
			AND NOT EXISTS (	SELECT S.CaseID  
								FROM CRM.LostLeadResponseStatuses S
								WHERE S.EventID = E.EventID
									AND S.CaseID = AEBI.CaseID
									AND S.ResponseStatusID = @CompletedStatusID	)		-- Where "Completed" status not already present
		GROUP BY AEBI.CaseID,
			E.EventID

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