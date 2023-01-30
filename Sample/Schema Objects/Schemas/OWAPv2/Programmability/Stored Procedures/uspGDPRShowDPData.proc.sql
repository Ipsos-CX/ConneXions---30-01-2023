
CREATE PROCEDURE [OWAPv2].[uspGDPRShowDPData]

	@PartyID BIGINT, 
	@RequestDateFrom DATE, 
	@RequestDateTo DATE, 
	@Validated BIT OUTPUT, 
	@ValidationFailureReason VARCHAR (255) OUTPUT
	
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
	Purpose:	Outputs the same info as the [SampleReporting].[GDPR].[uspErasuresFeedBuildBaseTable] proc but for a Party and/or Date Range
		
	Version		Date				Developer			Comment
	1.0			10/10/2018			Chris Ross			Created (See BUG 15033)
	1.1			21/01/2020			Chris Ledger		BUG 15372: Fix Hard coded references to databases.
*/


		------------------------------------------------------------------------
		-- Check params populated correctly
		------------------------------------------------------------------------

		SET @Validated = 0
	
		
		IF (@RequestDateFrom IS NOT NULL AND @RequestDateTo IS NULL)
		OR (@RequestDateFrom IS NULL AND @RequestDateTo IS NOT NULL)
		BEGIN
			SET @ValidationFailureReason = '@RequestDateFrom OR @RequestDateTo parameter is missing.  Either supply both, or neither.'
			RETURN 0
		END 

		IF @RequestDateFrom IS NULL AND @PartyID IS NULL
		BEGIN
			SET @ValidationFailureReason = 'No paramaters supplied.'
			RETURN 0
		END 

		SET @Validated = 1
	
		
		------------------------------------------------------------------------
		-- Populate the report base table with rows for PartyIDs not yet output
		------------------------------------------------------------------------

		SELECT DISTINCT 
				er.PartyID, 
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
		LEFT JOIN Event.Cases c ON c.CaseID = sq.CaseID
		WHERE (@RequestDateFrom IS NULL 
				OR er.RequestDate BETWEEN @RequestDateFrom AND @RequestDateTo)
			AND (@PartyID IS NULL
				 OR er.PartyID = @PartyID)



	
	RETURN 1



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

