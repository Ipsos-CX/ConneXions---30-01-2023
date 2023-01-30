
/* BUG 13566 (24/04/2017) - Chris Ross - This has been superseded by uspCalculateResponseStatuses proc *****************************

CREATE PROCEDURE [CRM].[uspAddNewBouncebacks] 
AS 
SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY



	--Purpose:	Adds Bouncebacks we have received to the CaseCRMBouncebacks table (for output to CRM)
		
	--Version		Date				Developer			Comment
	--1.0			12/07/2016			Chris Ross			Created
	--1.1			19/12/2016			Chris Ross			BUG 13424 - Add in filter to ensure no bouncbacks prior to 12/2016 are included.
	--1.25			15/01/2020			Chris Ledger		BUG 15372 - Fix Hard coded references to databases


BEGIN TRAN 
		
		-- Set a single date for load
		DECLARE @DateAddedForOutput DATETIME2
		SET @DateAddedForOutput = GETDATE()

		-- Insert into the CaseCRMUnsubscribes table
		;WITH CTE_ValidCRMParties
		AS (
			SELECT DISTINCT PartyIDFrom AS PartyID
			FROM [$(SampleDB)].Party.CustomerRelationships cr
			WHERE cr.CustomerIdentifier LIKE 'CRM_%'
			AND cr.CustomerIdentifierUsable = 1
		)
		INSERT INTO CRM.CaseCRMBouncebacks (CaseID, LoadedToConnexions, DateAddedForOutput)
		SELECT DISTINCT co.CaseID, co.DateLoaded, @DateAddedForOutput As DateAddedForOutput
		FROM  [$(AuditDB)].[Audit].[CustomerUpdate_ContactOutcome] co
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews aebi ON aebi.CaseID = co.CaseID
		INNER JOIN CTE_ValidCRMParties vcp ON vcp.PartyID = aebi.PartyID
		WHERE co.outcomecode IN (
									SELECT OutcomeCode FROM [$(SampleDB)].ContactMechanism.OutcomeCodes oc
									WHERE ISNULL(oc.HardBounce, 0) = 1 OR ISNULL(oc.SoftBounce, 0) = 1
								)
		AND co.DateProcessed IS NOT NULL
		AND NOT EXISTS (SELECT * FROM CRM.CaseCRMBouncebacks u WHERE u.CaseID = co.CaseID)  -- Check not already loaded
		AND co.DateLoaded > '2016-12-01'			-- v1.1

COMMIT


END TRY
BEGIN CATCH

	ROLLBACK;

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


*/