CREATE PROCEDURE [CRM].[uspCalculateResponseStatuses] 
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
	Purpose:	Calculate Response Statuses and add them to the CRM.CaseResponseStatuses table (for output to CRM)
				Incorporates old proc's spAddNewBouncebacks and spAddNewUnsubscribes.  Although, it is theoretically
				possible to add more than one status to this file at this time we will only actually output one in 
				the CRM.uspOutputXMLForBatch procedure.  Also, we add all statuses into this table rather than just
				latest so that we can check whether we have already recorded/output Bouncebacks, etc.
		
		Version		Date				Developer			Comment
LIVE	1.0			28/03/2017			Chris Ross			Created
LIVE	1.1			21/09/2017			Chris Ross			BUG 14122 - Add in PDI Check Flag on "Failed" status
															BUG 14257 - Remove triggering of failed on "EventAlreadySelected" flag plus add check that CaseID elsewhere in Logging for EventID. 
LIVE	1.2			05/12/2018			Chris Ross			BUG 15149 - Add in FromDate to checks for valid market/questionnaire combos, and now including Survey Completed.
LIVE	1.3			03/01/2019			Chris Ross			BUG 14568 - Add in check for rejections on Survey Not Responded status
LIVE	1.4			18/02/2019			Chris Ross			BUG 15266 - Change No Response status code to check the Loaded Date instead of Creation Date for valid from date.
LIVE	1.5			14/03/2019			Chris Ross			BUG 15294 - Change Unsubscribe and Bouncebacks to use Loaded date from logging table. Also, modified all checks to use >= to include the bang-on-midnight time.
LIVE	1.6			29/04/2019			Chris Ross			BUG 15371 - Add in check to "failed" status to ensure that EventIDs of value zero are not included.
LIVE	1.7			30/10/2019			Chris Ross			BUG 16718 - Add in functionality to group any duplicate supplied Bouncebacks and take the earliest action date.  This is in answer to a bug in the Online systems (currently being investigated).
LIVE	1.9			15/01/2020			Chris Ledger		BUG 15372 - Fix Hard coded references to databases
LIVE	1.10        19/02/2021          Chris Ledger        BUG 18110 - SV-CRM Feed Changes - Reformat code (no logic changes) 
LIVE	1.11		24/02/2021			Chris Ledger		BUG 18110 - Add in functionality to group any duplicate supplied unsubscribes and take the earliest action date.
LIVE	1.12		25/02/2021			Chris Ledger		BUG 18110 - Change survey completed logic
LIVE	1.13		24/05/2021			Chris Ledger		TASK 411 - Add CQIMissingExtraVehicleFeed & MissingPerson flags on "Failed" status
LIVE	1.14		01/02/2022			Chris Ledger		TASK 775 - Only append to CaseResponseStatuses table if CRM data
*/

	BEGIN TRAN 
	
		------------------------------------------------------------
		-- Get system values
		------------------------------------------------------------
		DECLARE @ResponseStatusFromDate DATE, 
				@DaysBeforeTriggeringNotResponedStatus INT
		SELECT @ResponseStatusFromDate = ResponseStatusFromDate ,
			@DaysBeforeTriggeringNotResponedStatus = DaysBeforeTriggeringNotResponedStatus
		FROM CRM.SystemValues 


		------------------------------------------------------------
		-- Set a single date for load
		------------------------------------------------------------
		DECLARE @DateAddedForOutput DATETIME2
		SET @DateAddedForOutput = GETDATE()
		
		
		------------------------------------------------------------
		-- Insert Case Bouncebacks
		------------------------------------------------------------
		
		-- Create temp table required to group any duplicate supplied bounceback	-- V1.7
		CREATE TABLE #Bouncebacks
		(
			CaseID				BIGINT,
			ResponseStatusID	INT,
			LoadedToConnexions	DATETIME2
		)
		
		-- Declare bounce type variables
		DECLARE @SoftBounceStatusID INT,
				@HardBounceStatusID INT 
		SELECT @SoftBounceStatusID = ResponseStatusID FROM CRM.ResponseStatuses WHERE ResponseStatus = 'Bounced-Soft'
		SELECT @HardBounceStatusID = ResponseStatusID FROM CRM.ResponseStatuses WHERE ResponseStatus = 'Bounced-Hard'
		
		-- Save initially to temp table for grouping purposes						-- V1.7
		INSERT INTO #Bouncebacks (CaseID, ResponseStatusID, LoadedToConnexions)     -- V1.7
		SELECT DISTINCT CO.CaseID, 
			CASE	WHEN CO.OutcomeCode IN (	SELECT OC.OutcomeCode 
												FROM [$(SampleDB)].ContactMechanism.OutcomeCodes OC
												WHERE ISNULL(OC.HardBounce, 0) = 1 )
					THEN @HardBounceStatusID  
					ELSE @SoftBounceStatusID END  AS BounceBack_ResponseStatusID,
			CO.DateLoaded
		FROM  [$(AuditDB)].Audit.CustomerUpdate_ContactOutcome CO
			INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = CO.CaseID
			INNER JOIN [$(AuditDB)].dbo.Files F ON SL.AuditID = F.AuditID										-- V1.14
			INNER JOIN CRM.vwValidResponseMarketQuestionnaires BMQ ON BMQ.Market = SL.Market 
																	AND BMQ.EventCategory = SL.Questionnaire
		WHERE CO.OutcomeCode IN (	SELECT OC.OutcomeCode 
									FROM [$(SampleDB)].ContactMechanism.OutcomeCodes OC
									WHERE ISNULL(OC.HardBounce, 0) = 1 
										OR ISNULL(OC.SoftBounce, 0) = 1 )
			AND CO.DateProcessed IS NOT NULL
			AND SUBSTRING(F.FileName,1,3) = 'CSD'																-- V1.14		
			AND NOT EXISTS (	SELECT S.CaseID 
								FROM CRM.CaseResponseStatuses S 
								WHERE S.CaseID = CO.CaseID 
									AND S.ResponseStatusID = (CASE	WHEN CO.OutcomeCode IN (	SELECT OC.OutcomeCode 
																								FROM [$(SampleDB)].ContactMechanism.OutcomeCodes OC 
																								WHERE ISNULL(OC.HardBounce, 0) = 1 )
																	THEN @HardBounceStatusID  
																	ELSE @SoftBounceStatusID END ) )  -- Check not already loaded
			AND CO.DateLoaded > '2016-12-01'			-- V1.1
			AND CO.DateLoaded > @ResponseStatusFromDate        
			AND SL.LoadedDate >= BMQ.FromDate			-- V1.2/V1.5


		-- Group by CaseID and ResponseStatusID to get Minimum LoadedToConnexions date for load on dupes -- V1.7
		INSERT INTO CRM.CaseResponseStatuses (CaseID, ResponseStatusID, LoadedToConnexions, DateAddedForOutput, AddedByProcess)
		SELECT CaseID, 
			ResponseStatusID,
			MIN(LoadedToConnexions) AS LoadedToConnexions, 
			@DateAddedForOutput AS DateAddedForOutput,
			'CRM.uspCalculateResponseStatuses' AS AddedByProcess
		FROM #Bouncebacks
		GROUP BY CaseID, 
			ResponseStatusID		



		------------------------------------------------------------
		-- Insert Case Unsubscribes 
		------------------------------------------------------------

		-- Create temp table required to group any duplicate supplied unsubscribes	-- V1.11
		CREATE TABLE #Unsubscribes
		(
			CaseID				BIGINT,
			ResponseStatusID	INT,
			LoadedToConnexions	DATETIME2
		)	

		DECLARE @UnsubscribeStatusID INT
		SELECT @UnsubscribeStatusID = ResponseStatusID FROM CRM.ResponseStatuses WHERE ResponseStatus = 'Unsubscribe'

		-- Save initially to temp table for grouping purposes						-- V1.11
		INSERT INTO #Unsubscribes (CaseID, ResponseStatusID, LoadedToConnexions)    -- V1.11
		SELECT DISTINCT CO.CaseID, 
			@UnsubscribeStatusID,
			CO.DateLoaded
		FROM  [$(AuditDB)].Audit.CustomerUpdate_ContactOutcome CO
			INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = CO.CaseID
			INNER JOIN [$(AuditDB)].dbo.Files F ON SL.AuditID = F.AuditID										-- V1.14
			INNER JOIN CRM.vwValidResponseMarketQuestionnaires BMQ ON BMQ.Market = SL.Market 
																	AND BMQ.EventCategory = SL.Questionnaire
		WHERE CO.OutcomeCode = 90 
			AND CO.DateProcessed IS NOT NULL
			AND NOT EXISTS (	SELECT * FROM CRM.CaseResponseStatuses S 
								WHERE S.CaseID = CO.CaseID 
									AND S.ResponseStatusID = @UnsubscribeStatusID )  -- Check not already loaded
			AND CO.DateLoaded > '2016-12-01'			-- V1.1
			AND CO.DateLoaded > @ResponseStatusFromDate        
			AND SUBSTRING(F.FileName,1,3) = 'CSD'		-- V1.14		
			AND SL.LoadedDate >= BMQ.FromDate			-- V1.2/V1.5

		-- Group by CaseID and ResponseStatusID to get Minimum LoadedToConnexions date for load on dupes -- V1.11
		INSERT INTO CRM.CaseResponseStatuses (CaseID, ResponseStatusID, LoadedToConnexions, DateAddedForOutput, AddedByProcess)
		SELECT CaseID, 
			ResponseStatusID,
			MIN(LoadedToConnexions) AS LoadedToConnexions, 
			@DateAddedForOutput AS DateAddedForOutput,
			'CRM.uspCalculateResponseStatuses' AS AddedByProcess
		FROM #Unsubscribes
		GROUP BY CaseID, 
			ResponseStatusID		



		------------------------------------------------------------
		-- Insert Survey Failed
		------------------------------------------------------------

		DECLARE @FailedStatusID INT
		SELECT @FailedStatusID = ResponseStatusID FROM CRM.ResponseStatuses WHERE ResponseStatus = 'Failed'

		INSERT INTO CRM.CaseResponseStatuses (EventID, ResponseStatusID, LoadedToConnexions, DateAddedForOutput, AddedByProcess)
		SELECT  SL.MatchedODSEventID, 
			@FailedStatusID,
			MIN(SL.LoadedDate) AS LoadedDate, 
			@DateAddedForOutput AS DateAddedForOutput,
			'CRM.uspCalculateResponseStatuses' AS AddedByProcess
		FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL 
			INNER JOIN [$(AuditDB)].dbo.Files F ON SL.AuditID = F.AuditID										-- V1.14
			INNER JOIN CRM.vwValidResponseMarketQuestionnaires BMQ ON BMQ.Market = SL.Market 
																	AND BMQ.EventCategory = SL.Questionnaire
		WHERE SUBSTRING(F.FileName,1,3) = 'CSD'							-- V1.14
			AND SL.LoadedDate > @ResponseStatusFromDate       
			AND SL.LoadedDate >= BMQ.FromDate							-- V1.2/V1.5
			AND SL.CaseID IS NULL
			AND SL.MatchedODSEventID <> 0								-- V1.6
			AND ( ISNULL(SL.EventDateOutOfDate, 0) = 1
				OR ISNULL(SL.EventNonSolicitation, 0) = 1
				OR ISNULL(SL.PartyNonSolicitation, 0) = 1
				OR ISNULL(SL.UnmatchedModel, 0) = 1
				OR ISNULL(SL.UncodedDealer, 0) = 1
				-- OR SL.EventAlreadySelected = 1						-- V1.1 - Do not include as these will already have Cases and associated CaseResponseStatuses 
				OR ISNULL(SL.NonLatestEvent, 0) = 1
				OR ISNULL(SL.InvalidOwnershipCycle, 0)	= 1
				OR ISNULL(SL.RecontactPeriod, 0) = 1
				OR ISNULL(SL.InvalidVehicleRole, 0) = 1                 
				OR ISNULL(SL.CrossBorderAddress, 0) = 1                 
				OR ISNULL(SL.CrossBorderDealer, 0)	= 1               
				OR ISNULL(SL.ExclusionListMatch, 0) = 1
				OR ISNULL(SL.InvalidEmailAddress, 0) = 1
				OR ISNULL(SL.BarredEmailAddress, 0) = 1
				OR ISNULL(SL.BarredDomain, 0) = 1
				OR ISNULL(SL.WrongEventType, 0) = 1
				OR ISNULL(SL.MissingStreet, 0) = 1
				OR ISNULL(SL.MissingPostcode, 0) = 1
				OR ISNULL(SL.MissingEmail, 0) = 1
				OR ISNULL(SL.MissingTelephone, 0) = 1
				OR ISNULL(SL.MissingStreetAndEmail, 0) = 1
				OR ISNULL(SL.MissingTelephoneAndEmail, 0) = 1
				OR ISNULL(SL.MissingMobilePhone, 0) = 1
				OR ISNULL(SL.MissingMobilePhoneAndEmail, 0) = 1
				OR ISNULL(SL.MissingPartyName, 0) = 1
				OR ISNULL(SL.MissingLanguage, 0) = 1
				--OR SL.RelativeRecontactPeriod = 1						-- We do not include this one as the event may still get selected.
				OR ISNULL(SL.InvalidManufacturer, 0) = 1
				OR ISNULL(SL.InternalDealer, 0) = 1
				OR ISNULL(SL.InvalidRoleType, 0) = 1          
				OR ISNULL(SL.InvalidSaleType, 0) = 1
				OR ISNULL(SL.DealerExclusionListMatch, 0) = 1
				OR ISNULL(SL.ContactPreferencesSuppression	, 0) = 1
				OR ISNULL(SL.PDIFlagSet, 0) = 1							-- V1.1
				OR ISNULL(SL.InvalidCRMSaleType, 0) = 1
				OR ISNULL(SL.CQIMissingExtraVehicleFeed, 0) = 1			-- V1.13
				OR ISNULL(SL.MissingPerson, 0) = 1						-- V1.13
				)
			AND NOT EXISTS (	SELECT S.EventID FROM CRM.CaseResponseStatuses S									-- Check not already loaded
								WHERE S.EventID = SL.MatchedODSEventID 
									AND S.ResponseStatusID = @FailedStatusID )										
			AND NOT EXISTS (	SELECT SL2.CaseID FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL2   -- V1.1 - Check that a CaseID does not exist for the Event
								WHERE SL2.MatchedODSEventID = SL.MatchedODSEventID
									AND SL2.CaseID IS NOT NULL )
		GROUP BY SL.MatchedODSEventID
		


		------------------------------------------------------------
		-- Insert Survey Completed
		------------------------------------------------------------

		-- Insert Completed Events
		DECLARE @CompletedStatusID INT
		SELECT @CompletedStatusID = ResponseStatusID FROM CRM.ResponseStatuses WHERE ResponseStatus = 'Completed'
			
		INSERT INTO CRM.CaseResponseStatuses (CaseID, ResponseStatusID, LoadedToConnexions, DateAddedForOutput, AddedByProcess)
		SELECT DISTINCT C.CaseID , 
			@CompletedStatusID AS ResponseStatusID, 
			C.ClosureDate AS LoadedToConnexions, 
			@DateAddedForOutput AS DateAddedForOutput,
			'CRM.uspCalculateResponseStatuses' AS AddedByProcess
		FROM [$(SampleDB)].Event.Cases C																			-- V1.12
			INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = C.CaseID		-- V1.2
			INNER JOIN [$(AuditDB)].dbo.Files F ON SL.AuditID = F.AuditID											-- V1.14
			INNER JOIN CRM.vwValidResponseMarketQuestionnaires BMQ ON BMQ.Market = SL.Market 
																	AND BMQ.EventCategory = SL.Questionnaire		-- V1.2
		WHERE C.ClosureDate IS NOT NULL													-- responded
			AND SL.LoadedDate >= BMQ.FromDate											-- V1.2/V1.5
			AND SUBSTRING(F.FileName,1,3) = 'CSD'										-- V1.14		
			AND NOT EXISTS (	SELECT S.CaseID  
								FROM CRM.CaseResponseStatuses S
								WHERE S.CaseID = C.CaseID
									AND S.ResponseStatusID = @CompletedStatusID	)		-- Where "Completed" status not already present



		------------------------------------------------------------
		-- Insert Survey Not Responded
		------------------------------------------------------------

		DECLARE @NotRespondedStatusID INT,
				@SentStatusID INT
	
		SELECT @NotRespondedStatusID = ResponseStatusID FROM CRM.ResponseStatuses WHERE ResponseStatus = 'Not Responded'
		SELECT @SentStatusID = ResponseStatusID FROM CRM.ResponseStatuses WHERE ResponseStatus = 'Sent'		
		
			
		INSERT INTO CRM.CaseResponseStatuses (CaseID, ResponseStatusID, LoadedToConnexions, DateAddedForOutput, AddedByProcess)
		SELECT  C.CaseID, 
			@NotRespondedStatusID,
			MIN(C.CreationDate) AS LoadedDate, 
			@DateAddedForOutput AS DateAddedForOutput,
			'CRM.uspCalculateResponseStatuses' AS AddedByProcess
		FROM [$(SampleDB)].Event.Cases C
			INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = C.CaseID 
			INNER JOIN [$(AuditDB)].dbo.Files F ON SL.AuditID = F.AuditID										-- V1.14
			INNER JOIN CRM.vwValidResponseMarketQuestionnaires BMQ ON BMQ.Market = SL.Market 
																	AND BMQ.EventCategory = SL.Questionnaire
		WHERE C.CreationDate > @ResponseStatusFromDate
			AND SL.LoadedDate >= BMQ.FromDate			-- V1.2  -- V1.4/V1.5
			AND SUBSTRING(F.FileName,1,3) = 'CSD'		-- V1.14		
			AND C.ClosureDate IS NULL					-- not responded yet
			AND DATEADD(DD, @DaysBeforeTriggeringNotResponedStatus, C.CreationDate) < GETDATE()  -- Over the number of days required to trigger "not responded"
			AND NOT EXISTS (	SELECT S.CaseID 
								FROM CRM.CaseResponseStatuses S 
								WHERE S.CaseID = C.CaseID 
									AND S.ResponseStatusID <> @SentStatusID )	-- Check nothing but "Sent" status present for the case
		
			AND NOT EXISTS (	SELECT CR.CaseID								-- V1.3
								FROM [$(SampleDB)].Event.CaseRejections CR 
								WHERE CR.CaseID = C.CaseID 
									AND ISNULL(CR.FromDate, '1900-01-01') < GETDATE() )
		GROUP BY C.CaseID


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