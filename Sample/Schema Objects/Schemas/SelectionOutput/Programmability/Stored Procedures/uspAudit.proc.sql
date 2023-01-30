CREATE PROC SelectionOutput.uspAudit
(
	@FileName VARCHAR(255),
	@RowCount INT,
	@Date DATETIME2,
	@AuditID dbo.AuditID OUTPUT
)
AS

/*
	Purpose:	Audit the output and return an AuditID
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created
	1.1				2018-03-09		Chris Ledger		Adjust to account for combined files which are auditted multiple times

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- CHECK TO SEE IF FILE ALREADY EXISTS
	SELECT @AuditID = ISNULL((SELECT TOP 1 AuditID FROM [Sample_Audit].dbo.Files WHERE FileName = @FileName),0)

	-- EXISTING FILE
	IF @AuditID > 0
	BEGIN
		UPDATE [$(AuditDB)].dbo.Files SET FileRowCount = FileRowCount + @RowCount WHERE AuditID = @AuditID
	END;
	
	
	-- NEW FILE
	IF @AuditID = 0
	BEGIN
	
		-- get an AuditID
		SELECT @AuditID = ISNULL(MAX(AuditID), 0) + 1 FROM [$(AuditDB)].dbo.Audit
		
		INSERT INTO [$(AuditDB)].dbo.Audit
		SELECT @AuditID

		INSERT INTO [$(AuditDB)].dbo.Files
		(
			AuditID,
			FileTypeID,
			FileName,
			FileRowCount,
			ActionDate
		)
		VALUES
		(
			@AuditID, 
			(SELECT FileTypeID FROM [$(AuditDB)].dbo.FileTypes WHERE FileType = 'Selection Output'),
			@FileName,
			@RowCount,
			@Date
		)

		INSERT INTO [$(AuditDB)].dbo.OutgoingFiles (AuditID, OutputSuccess)
		VALUES (@AuditID, 1)
	
	END;


	-- write back the AuditID
	UPDATE #OutputtedSelections
	SET AuditID = @AuditID
	WHERE AuditID IS NULL

	-- Create AuditItems
	DECLARE @max_AuditItemID INT
	SELECT @max_AuditItemID = ISNULL(MAX(AuditItemID), 0) FROM [$(AuditDB)].dbo.AuditItems

	-- Update AuditItemID in table by adding value above to autonumber
	UPDATE #OutputtedSelections
	SET AuditItemID = PhysicalRowID + @max_AuditItemID
	WHERE AuditID = @AuditID

	-- Insert rows from table into AuditItems
	INSERT INTO [$(AuditDB)].dbo.AuditItems (AuditItemID, AuditID)
	SELECT AuditItemID, AuditID
	FROM #OutputtedSelections
	WHERE AuditID = @AuditID

	-- Insert rows from table into FileRows
	INSERT INTO [$(AuditDB)].dbo.FileRows (AuditItemID, PhysicalRow)
	SELECT AuditItemID, PhysicalRowID
	FROM #OutputtedSelections
	WHERE AuditID = @AuditID


	-- Record the output in CaseOutput
	INSERT INTO Event.CaseOutput (CaseID, AuditID, AuditItemID, CaseOutputTypeID)
	SELECT CaseID, AuditID, AuditItemID, CaseOutputTypeID
	FROM #OutputtedSelections
		
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