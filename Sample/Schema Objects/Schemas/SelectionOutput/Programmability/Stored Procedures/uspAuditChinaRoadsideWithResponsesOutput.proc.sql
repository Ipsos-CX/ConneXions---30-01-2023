CREATE PROCEDURE [SelectionOutput].[uspAuditChinaRoadsideWithResponsesOutput]
@FileName VARCHAR (255)
AS
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
			CaseOutputTypeID INT NULL
		)

		DECLARE @RowCount INT
		DECLARE @AuditID dbo.AuditID

		INSERT INTO #OutputtedSelections (CaseID, PartyID, CaseOutputTypeID)
		SELECT DISTINCT
			O.[ID] AS CaseID, 
			O.PartyID,
			(SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'Online') AS CaseOutputTypeID
		FROM SelectionOutput.OnlineOutput O
		INNER JOIN Sample_ETL.China.Roadside_WithResponses CSE ON O.ID = CSE.CaseID 	
		
		
		-- get the RowCount
		SET @RowCount = (SELECT COUNT(*) FROM #OutputtedSelections)

		IF @RowCount > 0
		BEGIN
		
			EXEC SelectionOutput.uspAudit @FileName, @RowCount, @Date, @AuditID OUTPUT
			
			INSERT INTO [$(Sample_Audit)].Audit.SelectionOutput
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
				[Expired],
				[DateOutput],
				ITYPE,					--v1.1
				PilotCode				--v1.1
			)
			SELECT DISTINCT
				O.[AuditID], 
				O.[AuditItemID], 
				(SELECT SelectionOutputTypeID FROM [$(Sample_Audit)].dbo.SelectionOutputTypes WHERE SelectionOutputType = 'Email') AS [SelectionOutputTypeID],
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
				S.[Expired],
				@Date,
				S.ITYPE,			--v1.1
				S.Pilotcode			--v1.1
			FROM #OutputtedSelections O
			INNER JOIN SelectionOutput.OnlineOutput S ON O.CaseID = S.[ID]
								AND O.PartyID = S.PartyID
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