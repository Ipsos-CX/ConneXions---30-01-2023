
CREATE PROCEDURE SelectionOutput.uspUpdateLostLeadOutputStatusCATI
@OutputFileName VARCHAR (255) 
AS
SET NOCOUNT ON

--------------------------------------------------------------------------------------------
--
-- Name : SelectionOutput.uspUpdateLostLeadOutputStatusCATI
--
-- Desc : Update the LLostLeads.CaseLostLeadStatuses table with LostLead Cases just output
--
-- Change History...
-- 
-- Version	Date		Author		Description
-- =======	====		======		===========
--	1.0		16-02-2018	Chris Ross	Original version (BUG 14413)
--
--------------------------------------------------------------------------------------------


DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


BEGIN TRAN 

		---------------------------------------------------------------------------------------------------------------
		-- Add appropriate Lost Lead status for CATI output Lost Lead Cases  (including saving the output Agency code)
		---------------------------------------------------------------------------------------------------------------

		-- Set a single date for load
		DECLARE @DateAddedForOutput DATETIME2
		SET @DateAddedForOutput = GETDATE()
		
		-- Get the correct Lost Lead status ID
		DECLARE @SentByCATILeadStatus  INT
		SELECT @SentByCATILeadStatus  = LeadStatusId FROM SampleReporting.LostLeads.LostLeadStatuses WHERE LeadStatus = 'Sent via CATI'


		-- Get the Cases (and associated agencies) that we are going to create Statuses for...
		IF OBJECT_ID('tempdb..#CaseAndLLA') IS NOT NULL
		DROP TABLE #CaseAndLLA

		CREATE TABLE #CaseAndLLA
			(
				CaseID			BIGINT,
				AgencyShortName	NVARCHAR(50)
			)
		
		INSERT INTO #CaseAndLLA (CaseID, AgencyShortName)
		SELECT C.ID, LLA.AgencyShortName
		FROM [$(AuditDB)].dbo.files f
		INNER JOIN [$(AuditDB)].dbo.AuditItems ai On ai.AuditID = f.AuditID
		INNER JOIN [$(AuditDB)].Audit.SelectionOutput so ON so.AuditItemID = ai.AuditItemID
		INNER JOIN SelectionOutput.CATICLP	C ON C.ID = so.CaseID
		INNER JOIN dbo.Markets	MK ON C.ccode		= MK.CountryID
		INNER JOIN dbo.Regions	RG ON MK.RegionID	= RG.RegionID
		INNER JOIN ContactMechanism.Countries CO ON MK.CountryID = CO.CountryID
		LEFT JOIN [$(ETLDB)].Lookup.LostLeadsAgencyStatus LLR ON C.GDDDealerCode = LLR.CICode
															AND LLR.Market = CO.ISOAlpha2
		LEFT JOIN SelectionOutput.LostLeadAgencies LLA ON LLR.LostSalesProvider = LLA.Agency
		WHERE f.filename = @OutputFilename
		and c.DateOutput IS NULL
		
		-- Get the data for first received row (AuditItemID) 
		IF OBJECT_ID('tempdb..#AuditIDsOrdered') IS NOT NULL
		DROP TABLE #AuditIDsOrdered

		CREATE TABLE #AuditIDsOrdered
			(
				RowID			INT,
				CaseID			BIGINT,
				AuditID			BIGINT,
				AuditItemID		BIGINT,
				MatchedODSEventID BIGINT
			)

		INSERT INTO #AuditIDsOrdered (RowID, CaseID, AuditID, AuditItemID, MatchedODSEventID)
		SELECT  ROW_NUMBER() OVER(PARTITION BY c.CaseID ORDER BY AuditItemID DESC) AS RowID,
				c.CaseID, sq.AuditID, sq.AuditItemID, sq.MatchedODSEventID
		FROM #CaseAndLLA c
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging sq ON sq.CaseID = c.CaseID 
		
		
		-- Insert into LostLeads.CaseLostLeadStatuses table
		INSERT INTO [$(SampleReporting)].LostLeads.CaseLostLeadStatuses (CaseID, EventID, LeadStatusID, LoadedToConnexions, DateAddedForOutput, AddedByProcess, OutputAgencyCode)
		SELECT DISTINCT 
						c.CaseID , 
						c.MatchedODSEventID,
						@SentByCATILeadStatus AS LeadStatusID, 
						f.ActionDate AS LoadedToConnexions, 
						@DateAddedForOutput AS DateAddedForOutput,
						'SelectionOutput.uspUpdateLostLeadOutputStatusCATI' AS AddedByProcess,
						cl.AgencyShortName 
		FROM #AuditIDsOrdered c
		INNER JOIN #AuditIDsOrdered oi ON oi.CaseID = c.CaseID AND oi.RowId = 1
		INNER JOIN #CaseAndLLA cl ON cl.CaseID = c.CaseID
		INNER JOIN [$(AuditDB)].dbo.Files f ON f.AuditID = c.AuditID

	


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


