CREATE PROCEDURE [GDPR].[uspErasuresFeedBuildBaseTable]
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
	Purpose:	Clears down and populates the report base table and adds new PartyIDs for output.
		
	Version		Date				Developer			Comment
	1.0			02/07/2018			Chris Ross			Created (See BUG 14824)
	1.1			12/07/2018			Chris Ross			BUG 14854 - Add in new columns (Market, Survey, FileLoadDate, Responded)
	1.2			15/01/2020			Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/

	
		------------------------------------------------------------
		-- Truncate the report base table
		------------------------------------------------------------
		
		TRUNCATE TABLE  GDPR.ErasuresFeedBaseTable


BEGIN TRAN 

		------------------------------------------------------------------------
		-- Populate the report base table with rows for PartyIDs not yet output
		------------------------------------------------------------------------

		INSERT INTO GDPR.ErasuresFeedBaseTable (PartyID, ErasureDate, AuditItemID, CaseID, Market, Survey, FileLoadDate, RespondedDate)
		SELECT DISTINCT er.PartyID, 
				CONVERT(DATE, er.RequestDate, 20) AS ErasureDate, 
				sq.AuditItemID, 
				sq.CaseID,
				sq.Market,
				sq.Questionnaire AS Survey,
				f.ActionDate AS FileLoadDate,
				c.ClosureDate AS RespondedDate				
		FROM [$(AuditDB)].GDPR.ErasureRequests er
		INNER JOIN [$(WebsiteReporting)].[dbo].[SampleQualityAndSelectionLogging] sq ON sq.MatchedODSPersonID = er.PartyID
		INNER JOIN [$(AuditDB)].dbo.Files f ON f.AuditID = sq.AuditID
		LEFT JOIN [$(SampleDB)].Event.Cases c ON c.CaseID = sq.CaseID
		WHERE NOT EXISTS (SELECT efp.PartyID FROM GDPR.ErasuresFeedParties efp WHERE efp.PartyID = er.PartyID)


		------------------------------------------------------------------------
		-- Add the PartyIDs into the reference table for tracking
		------------------------------------------------------------------------
		INSERT INTO GDPR.ErasuresFeedParties (PartyID)
		SELECT DISTINCT PartyID
		FROM GDPR.ErasuresFeedBaseTable 
		
		
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

