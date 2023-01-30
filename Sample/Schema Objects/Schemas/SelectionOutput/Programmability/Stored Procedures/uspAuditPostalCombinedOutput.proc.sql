CREATE PROC SelectionOutput.uspAuditPostalCombinedOutput
(
	@Brand [dbo].[OrganisationName], @Market [dbo].[Country], @Questionnaire [dbo].[Requirement], @LanguageID INT, @FileName VARCHAR(255)
)
AS

/*
	Purpose:	Audit the postal combined output
	
	Version			Date			Developer			Comment
	1.0				2017-03-15		Chris Ledger		Created
	1.1				2017-07-14		Chris Ledger		Add Batch
	1.2				2017-10-23		Chris Ledger		Add Bilingual Language Filter
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN
	
		DECLARE @Date DATETIME
		SET @Date = GETDATE()
		
		-- CREATE A TEMP TABLE TO HOLD EACH TYPE OF OUTPUT
		CREATE TABLE #OutputtedSelections
		(
			PhysicalRowID INT IDENTITY(1,1) NOT NULL,
			AuditID INT NULL,
			AuditItemID INT NULL,
			CaseID INT NULL,
			PartyID INT NULL,
			lang INT NULL,				-- V1.2
			CaseOutputTypeID INT NULL
		)

		DECLARE @RowCount INT
		DECLARE @AuditID dbo.AuditID

		INSERT INTO #OutputtedSelections (CaseID, PartyID, lang, CaseOutputTypeID)
		SELECT DISTINCT
			[ID] AS CaseID, 
			PartyID,
			PC.lang,	-- V1.2
			(SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'Postal') AS CaseOutputTypeID
		FROM SelectionOutput.PostalCombined PC
		INNER JOIN Requirement.SelectionCases SC ON PC.ID = SC.CaseID
		INNER JOIN Requirement.RequirementRollups RR ON SC.RequirementIDPartOf = RR.RequirementIDMadeUpOf
		INNER JOIN Requirement.Requirements R ON RR.RequirementIDPartOf = R.RequirementID
		INNER JOIN Sample.dbo.vwBrandMarketQuestionnaireSampleMetadata SM ON R.RequirementID = SM.QuestionnaireRequirementID
		WHERE PC.DateOutput IS NULL AND 
		PC.Outputted = 1 AND	-- V1.1
		SM.Brand = @Brand AND
		SM.Questionnaire = @Questionnaire AND
		PC.CTRY = @Market AND
		(ISNULL(PC.BilingualFlag,'FALSE') = 'FALSE' OR PC.lang = @LanguageID)			-- V1.2 Bilgingual Language
	
		-- get the RowCount
		SET @RowCount = (SELECT COUNT(*) FROM #OutputtedSelections)

		IF @RowCount > 0
		BEGIN
		
			EXEC SelectionOutput.uspAudit @FileName, @RowCount, @Date, @AuditID OUTPUT
			
			INSERT INTO [$(AuditDB)].Audit.SelectionOutput
			(
				[AuditID], 
				[AuditItemID], 
				[SelectionOutputTypeID], 
				[PartyID], 
				[CaseID], 
				[FullModel], 
				[Model], 
				[sType], 
				[CarReg], 
				[Title], 
				[Initial], 
				[Surname], 
				[Fullname], 
				[DearName], 
				[CoName], 
				[Add1], 
				[Add2], 
				[Add3], 
				[Add4], 
				[Add5], 
				[Add6], 
				[Add7], 
				[Add8], 
				[Add9], 
				[CTRY], 
				[EmailAddress], 
				[Dealer], 
				[sno], 
				[ccode], 
				[modelcode], 
				[lang], 
				[manuf], 
				[gender], 
				[qver], 
				[blank], 
				[etype], 
				[reminder], 
				[week], 
				[test], 
				[SampleFlag], 
				[SalesServiceFile],
				[BilingualFlag],		-- V1.2
				[DateOutput]
				
			)
			SELECT DISTINCT
				O.[AuditID], 
				O.[AuditItemID], 
				(SELECT SelectionOutputTypeID FROM [$(AuditDB)].dbo.SelectionOutputTypes WHERE SelectionOutputType = 'Postal') AS [SelectionOutputTypeID],
				S.[PartyID], 
				S.[ID] AS [CaseID], 
				S.[FullModel], 
				S.[Model], 
				S.[sType], 
				S.[CarReg], 
				S.[Title], 
				S.[Initial], 
				S.[Surname], 
				S.[Fullname], 
				S.[DearName], 
				S.[CoName], 
				S.[Add1], 
				S.[Add2], 
				S.[Add3], 
				S.[Add4], 
				S.[Add5], 
				S.[Add6], 
				S.[Add7], 
				S.[Add8], 
				S.[Add9], 
				S.[CTRY], 
				S.[EmailAddress], 
				S.[Dealer], 
				S.[sno], 
				S.[ccode], 
				S.[modelcode], 
				S.[lang], 
				S.[manuf], 
				S.[gender], 
				S.[qver], 
				S.[blank], 
				S.[etype], 
				S.[reminder], 
				S.[week], 
				S.[test], 
				S.[SampleFlag], 
				S.[SalesServiceFile],
				S.[BilingualFlag],		-- V1.2
				@Date
			FROM #OutputtedSelections O
			INNER JOIN SelectionOutput.PostalCombined S ON O.CaseID = S.[ID]
								AND O.PartyID = S.PartyID
								AND O.lang = S.lang	-- V1.2
			WHERE S.DateOutput IS NULL	-- V1.1
			AND S.Outputted = 1			-- V1.1
			ORDER BY O.AuditItemID

		END

		-- DROP THE TEMPORARY TABLE
		DROP TABLE #OutputtedSelections
		
	COMMIT TRAN
		
END TRY
BEGIN CATCH

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
		
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH