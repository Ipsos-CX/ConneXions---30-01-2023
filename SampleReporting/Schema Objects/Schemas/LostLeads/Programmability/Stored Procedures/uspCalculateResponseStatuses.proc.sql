CREATE PROCEDURE [LostLeads].[uspCalculateResponseStatuses]
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
	Purpose:	Calculate Response Statuses and add them to the LostLeads.CaseLostLeadStatuses table (for output to Bluefin)
		
	Version		Date				Developer			Comment
	1.0			15/02/2018			Chris Ross			Created (See BUG 14413)
	1.1			29/10/2019			Chris Ledger		Add PreOwned LostLeads
	1.2			15/01/2020			Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/

BEGIN TRAN 

		------------------------------------------------------------
		-- Get system values
		------------------------------------------------------------
		DECLARE @LostLeadStatusFromDate DATE
		SELECT @LostLeadStatusFromDate = LostLeadStatusFromDate FROM LostLeads.SystemValues 

		
		------------------------------------------------------------
		-- Set a single date for load
		------------------------------------------------------------
		DECLARE @DateAddedForOutput DATETIME2
		SET @DateAddedForOutput = GETDATE()

	
		-------------------------------------------------------------------
		-- Check only expected (valid) response statuses are present
		-------------------------------------------------------------------
	
		DECLARE @count int
		SELECT @count = COUNT(DISTINCT rs.CaseID) 
				FROM [$(SampleDB)].Event.CaseLostLeadResponses rs
				LEFT JOIN LostLeads.CRMLeadStatusCodes sc ON sc.KeyValue = rs.LeadStatus
														 AND sc.LeadStatus IN ('Lost Sales LLA', 'Resurrected')
				WHERE NOT EXISTS (SELECT cls.CaseID FROM LostLeads.CaseLostLeadStatuses cls WHERE cls.CaseID = rs.CaseID)
				AND sc.KeyValue IS NULL

		IF 0 < @count
		RAISERROR ('ERROR (LostLeads.uspCalculateResponsestatuses) : Unexpected Lead Status Codes.  Please investigate.',  16, 1) 


			
		---------------------------------------------------------------------------------------------
		-- Check status values from DP only have one corresponding LeadStatusCode entry for output
		---------------------------------------------------------------------------------------------
	
		IF 0 < (SELECT COUNT(*) - COUNT(DISTINCT sc.KeyValue)
				FROM [LostLeads].[LostLeadStatuses] lls
				INNER JOIN LostLeads.CRMLeadStatusCodes sc ON sc.KeyValue = lls.LeadStatusCRMKeyValue
																 AND sc.LeadStatus IN ('Lost Sales LLA', 'Resurrected')
				)
		RAISERROR ('ERROR (LostLeads.uspCalculateResponsestatuses) : Allowable CRM key values linked to mutilple Lead Status Codes.  Please investigate.',  16, 1) 
			
		
	
		------------------------------------------------------------
		-- Insert Received Events
		------------------------------------------------------------
		
		-- Get the Lost Lead status ID
		DECLARE @ReceivedByGfKStatusID  INT
		SELECT @ReceivedByGfKStatusID = LeadStatusID FROM LostLeads.LostLeadStatuses WHERE LeadStatus = 'Received by GfK'


		INSERT INTO LostLeads.CaseLostLeadStatuses (EventID, LeadStatusID, LoadedToConnexions, DateAddedForOutput, AddedByProcess)
		SELECT sq.MatchedODSEventID , 
				@ReceivedByGfKStatusID , 
				MIN(sq.LoadedDate) AS LoadedToConnexions, 
				@DateAddedForOutput AS DateAddedForOutput,
				'LostLead.uspCalculateResponseStatuses' AS AddedByProcess
			FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging sq 
		WHERE sq.LoadedDate > @LostLeadStatusFromDate  
		AND sq.Questionnaire IN ('LostLeads','PreOwned LostLeads')		-- V1.1
		AND NOT EXISTS (SELECT u.EventID FROM LostLeads.CaseLostLeadStatuses u 
						WHERE u.EventID = sq.MatchedODSEventID 
						AND u.LeadStatusID = @ReceivedByGfKStatusID)  -- Check not already loaded
		GROUP BY sq.MatchedODSEventID 


		
		------------------------------------------------------------
		-- Insert Survey Completed Values
		------------------------------------------------------------

		-- Insert Completed Events
		INSERT INTO LostLeads.CaseLostLeadStatuses (CaseID, EventID, LeadStatusID, LoadedToConnexions, DateAddedForOutput, AddedByProcess)
		SELECT DISTINCT 
				llr.CaseID  , 
				AEBI.EventID,
				ls.LeadStatusID, 
				llr.ResponseDate AS LoadedToConnexions, 
				@DateAddedForOutput AS DateAddedForOutput,
				'LostLead.uspCalculateResponseStatuses' AS AddedByProcess
		FROM [$(SampleDB)].Event.CaseLostLeadResponses llr
		INNER JOIN LostLeads.CRMLeadStatusCodes sc ON sc.KeyValue = llr.LeadStatus AND sc.LeadStatus IN ('Lost Sales LLA', 'Resurrected')
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = llr.CaseID
		INNER JOIN LostLeads.LostLeadStatuses ls ON ls.LeadStatusCRMKeyValue = sc.KeyValue			-- This is dependent on the keyvalues values only having one corresponding LeadStatusCode each (see check above)
		WHERE NOT EXISTS (SELECT cls.CaseID FROM LostLeads.CaseLostLeadStatuses cls -- Do not add if the response aleady present
							WHERE cls.CaseID = llr.CaseID
							AND cls.LeadStatusID = ls.LeadStatusID) 



		---------------------------------------------------------------------------------------------
		-- Check no NULL lead statuses present.  This can happen if there is an output type in 
		-- Selection Output process which does not have corresponding lead status value.
		---------------------------------------------------------------------------------------------
	
		IF 0 < (SELECT COUNT(*)
				FROM [LostLeads].[CaseLostLeadStatuses] clls
				LEFT JOIN LostLeads.LostLeadStatuses sc ON sc.LeadStatusID = clls.LeadStatusID
				WHERE sc.LeadStatusID IS NULL
				)
		RAISERROR ('ERROR (LostLeads.uspCalculateResponsestatuses) : Lead Status Codes not found.  Please investigate.',  16, 1) 
			
	

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