CREATE PROCEDURE SelectionOutput.uspUpdateCasesFromOutput
AS
SET NOCOUNT ON

/*
		Name : SelectionOutput.uspUpdateCasesFromOutput
		Desc : Update the On-line Expiry Dates and Passwords on Cases table 

		Version	Date		Author			Description
		=======	====		======			===========
LIVE	1.0		12-02-2013	Chris Ross		Original version (Taken from uspUpdateCasesOnlineExpiryDate.proc)
LIVE	1.1		19-04-2017	Chris Ross		BUG 13566 - Add sent status for each Case to the CRM.CaseResponseStatus table
LIVE	1.2		16-02-2018	Chris Ross		BUG 14413 - Update to output the sent status for On-line output Lost Leads record
LIVE	1.3		14-08-2018  Eddie Thomas	BUG 14797 - Portugal Roadside - Contact Methodology Change request	
LIVE	1.4		06-12-2018	Chris Ross		BUG 15149 - Add in FromDate to check for valid market/questionnaire combos in Case Response Status update
LIVE	1.5		29-10-2019	Chris Ledger	BUG 15490 - Add PreOwned LostLeads
LIVE	1.6		08-04-2021	Chris Ledger	Remove V1.4
LIVE	1.7		14-04-2021	Chris Ledger	Tidy formatting and only run Lost Leads if required to speed up
LIVE	1.8		01-02-2022	Chris Ledger	TASK 774 - Remove update of CRM.CaseLostLeadStatuses table (no longer used)
LIVE	1.9		01-02-2022	Chris Ledger	TASK 774 - Only update CRM.CaseResponseStatus table if CRM data 
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN 
		
		---------------------------------------------------------------------
		-- Update Expiry Date
		---------------------------------------------------------------------
		UPDATE C
		SET C.OnlineExpiryDate = OO.Expired 
		FROM SelectionOutput.OnlineOutput OO 
			INNER JOIN Event.Cases C ON C.CaseID = OO.ID 
		WHERE OO.Expired IS NOT NULL
			AND OO.ITYPE = 'H'					-- on-line
			AND C.OnlineExpiryDate IS NULL
		---------------------------------------------------------------------

		
		---------------------------------------------------------------------
		-- V1.3 Portugal Roadside - Contact Methodology Change request 
		---------------------------------------------------------------------
		DECLARE @CMTid INT
		SELECT	@CMTid = ContactMethodologyTypeID 
		FROM SelectionOutput.ContactMethodologyTypes 
		WHERE ContactMethodologyType ='Mixed (SMS & Email)'											

		UPDATE C		
		SET C.OnlineExpiryDate = OO.Expired
		FROM SelectionOutput.OnlineOutput OO 
			INNER JOIN Event.Cases C ON C.CaseID = OO.ID
			INNER JOIN Meta.CaseDetails CD ON OO.ID = CD.CaseID 
											AND OO.PartyID	= CD.PartyID	
			INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata MD ON CD.QuestionnaireRequirementID = MD.QuestionnaireRequirementID																								
		WHERE OO.Expired IS NOT NULL
			AND OO.ITYPE = 'S'											-- SMS
			AND	C.OnlineExpiryDate IS NULL
			AND	ISNULL(MD.NumDaysToExpireOnlineQuestionnaire,0) > 0		-- ONLY QUESTIONNAIRES SET UP TO EXPIRE
			AND	MD.ContactMethodologyTypeID = @CMTid					-- ONLY MIXED CONTACT METHODOLOGY SMS & Email
		---------------------------------------------------------------------

		
		---------------------------------------------------------------------
		-- Update SelectionOutputPassword 
		---------------------------------------------------------------------
		UPDATE C
		SET C.SelectionOutputPassword = OO.Password
		FROM SelectionOutput.OnlineOutput OO 
			INNER JOIN Event.Cases C ON C.CaseID = OO.ID 
		---------------------------------------------------------------------
		
		
		---------------------------------------------------------------------
		-- V1.1 Add sent status for each Case to the CRM.CaseResponseStatus table
		---------------------------------------------------------------------	
		
		-- Get system values
		DECLARE @ResponseStatusFromDate DATE
		SELECT @ResponseStatusFromDate = ResponseStatusFromDate 
		FROM [$(SampleReporting)].[CRM].[SystemValues] 

		-- Set a single date for load
		DECLARE @DateAddedForOutput DATETIME2
		SET @DateAddedForOutput = GETDATE()

		-- Get status
		DECLARE @SentStatusID INT
		SELECT @SentStatusID = ResponseStatusID 
		FROM [$(SampleReporting)].CRM.ResponseStatuses 
		WHERE ResponseStatus = 'Sent'		

		-- insert into CaseRsponseStatuses table
		INSERT INTO [$(SampleReporting)].CRM.CaseResponseStatuses (CaseID, ResponseStatusID, LoadedToConnexions, DateAddedForOutput, AddedByProcess)
		SELECT DISTINCT C.CaseID, 
			@SentStatusID,
			C.CreationDate, 
			@DateAddedForOutput As DateAddedForOutput,
			'SelectionOutput.uspUpdateCasesFromOutput' AS AddedByProcess
		FROM  SelectionOutput.OnlineOutput OO
			INNER JOIN Event.Cases C ON C.CaseID = OO.ID
			INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = C.CaseID 
			INNER JOIN [$(AuditDB)].dbo.Files F ON SL.AuditID = F.AuditID								-- 1.9
			INNER JOIN [$(SampleReporting)].CRM.vwValidResponseMarketQuestionnaires VMQ ON VMQ.Market = SL.Market 
																							AND VMQ.EventCategory = SL.Questionnaire
		WHERE C.CreationDate > @ResponseStatusFromDate			-- Only Cases created after inception date
			AND SUBSTRING(F.FileName,1,3) = 'CSD'				-- V1.9		
			--AND C.CreationDate > VMQ.FromDate					-- V1.4	V1.6
			AND NOT EXISTS (	SELECT * 
								FROM [$(SampleReporting)].CRM.CaseResponseStatuses U 
								WHERE U.CaseID = C.CaseID 
									AND U.ResponseStatusID = @SentStatusID)  -- Check not already loaded



		---------------------------------------------------------------------
		-- V1.8 REMOVED V1.2 Add appropriate Lost Lead status for On-line output Lost Lead Cases
		---------------------------------------------------------------------
		/*
		-- Get status
		DECLARE @SentViaEmailStatusID INT,
			@SentByCATILeadStatus  INT

		SELECT @SentByCATILeadStatus = LeadStatusID 
		FROM SampleReporting.LostLeads.LostLeadStatuses
		WHERE LeadStatus = 'Sent via CATI'
		
		SELECT @SentViaEmailStatusID = LeadStatusID 
		FROM SampleReporting.LostLeads.LostLeadStatuses 
		WHERE LeadStatus = 'Sent via Email'
		
		DECLARE @LostLeadsInOutput INT = 0

		SELECT @LostLeadsInOutput = CASE WHEN ET.EventType IN ('LostLeads','PreOwned LostLeads') THEN 1 ELSE 0 END	-- V1.7
		FROM SelectionOutput.OnlineOutput OO
			INNER JOIN Sample.Event.EventTypes ET ON OO.etype = ET.EventTypeID
		WHERE ET.EventType IN ('LostLeads','PreOwned LostLeads')
		GROUP BY CASE WHEN ET.EventType IN ('LostLeads','PreOwned LostLeads') THEN 1 ELSE 0 END

		IF @LostLeadsInOutput = 1
		BEGIN

			-- Insert into LostLeads.CaseResponseStatuses table
			INSERT INTO [$(SampleReporting)].LostLeads.CaseLostLeadStatuses (CaseID, EventID, LeadStatusID, LoadedToConnexions, DateAddedForOutput, AddedByProcess)
			SELECT DISTINCT 
				C.CaseID, 
				SL.MatchedODSEventID,
				@SentViaEmailStatusID AS LeadStatus,
				C.CreationDate, 
				@DateAddedForOutput As DateAddedForOutput,
				'SelectionOutput.uspUpdateCasesFromOutput' AS AddedByProcess
			FROM  SelectionOutput.OnlineOutput OO
				INNER JOIN Event.Cases C ON C.CaseID = OO.ID
				INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = C.CaseID 
			WHERE SL.Questionnaire IN ('LostLeads','PreOwned LostLeads')							-- V1.5
				AND OO.ITYPE = 'H'	-- On-line output only
				AND NOT EXISTS (	SELECT CLS.CaseID 
									FROM [$(SampleReporting)].LostLeads.CaseLostLeadStatuses CLS	-- Check not already loaded
									WHERE CLS.CaseID = C.CaseID
										AND CLS.LeadStatusID = @SentViaEmailStatusID)  
			UNION
			SELECT DISTINCT 
				C.CaseID, 
				SL.MatchedODSEventID,
				@SentByCATILeadStatus AS LeadStatus,
				C.CreationDate, 
				@DateAddedForOutput As DateAddedForOutput,
				'SelectionOutput.uspUpdateCasesFromOutput' AS AddedByProcess
			FROM  SelectionOutput.OnlineOutput OO
				INNER JOIN Event.Cases C ON C.CaseID = OO.ID
				INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = C.CaseID 
			WHERE SL.Questionnaire IN ('LostLeads','PreOwned LostLeads')							-- V1.5
				AND OO.ITYPE = 'T'	-- Telephone output only
				AND NOT EXISTS (	SELECT CLS.CaseID 
									FROM [$(SampleReporting)].LostLeads.CaseLostLeadStatuses CLS	-- Check not already loaded
									WHERE CLS.CaseID = C.CaseID
										AND CLS.LeadStatusID = @SentByCATILeadStatus)  
				AND NOT EXISTS (	SELECT M.Brand
									FROM dbo.vwBrandMarketQuestionnaireSampleMetadata M
									WHERE M.Brand = SL.Brand
										AND M.CountryID = OO.ccode
										AND M.Questionnaire = SL.Questionnaire
										AND M.CATIMerged = 1)
		END
		*/

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

	EXEC [Sample_Errors].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH


