CREATE PROC SelectionOutput.uspAuditNonOutput
(
	@FileName VARCHAR(255)
)
AS

/*
	Purpose:	Audit the postal output
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created

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
			CaseOutputTypeID INT NULL
		)

		DECLARE @RowCount INT
		DECLARE @AuditID dbo.AuditID

		INSERT INTO #OutputtedSelections (CaseID, PartyID, CaseOutputTypeID)
		SELECT DISTINCT
			CaseID, 
			PartyID,
			(SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'Non Output') AS CaseOutputTypeID
		FROM SelectionOutput.NonOutput
		
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
				[CaseID], 
				[PartyID],
				[DateOutput]
			)
			SELECT DISTINCT
				O.[AuditID], 
				O.[AuditItemID], 
				(SELECT SelectionOutputTypeID FROM [$(AuditDB)].dbo.SelectionOutputTypes WHERE SelectionOutputType = 'NonOutput') AS [SelectionOutputTypeID],
				S.[CaseID], 
				S.[PartyID],
				@Date
			FROM #OutputtedSelections O
			INNER JOIN SelectionOutput.NonOutput S ON O.CaseID = S.CaseID
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