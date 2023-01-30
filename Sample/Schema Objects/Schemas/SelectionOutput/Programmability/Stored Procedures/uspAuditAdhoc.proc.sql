CREATE PROCEDURE [SelectionOutput].[uspAuditAdhoc]
@FileName VARCHAR (255), @RowCount INT, @Date DATETIME2 (7), @AuditID [dbo].[AuditID] OUTPUT
AS
SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- get an AuditID
	SELECT @AuditID = ISNULL(MAX(AuditID), 0) + 1 FROM [$(Sample_Audit)].dbo.Audit
	
	INSERT INTO [$(Sample_Audit)].dbo.Audit
	SELECT @AuditID

	INSERT INTO [$(Sample_Audit)].dbo.Files
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
		(SELECT FileTypeID FROM [$(Sample_Audit)].dbo.FileTypes WHERE FileType = 'Selection Output'),
		@FileName,
		@RowCount,
		@Date
	)

	INSERT INTO [$(Sample_Audit)].dbo.OutgoingFiles (AuditID, OutputSuccess)
	VALUES (@AuditID, 1)

	-- CREATE A TEMP TABLE TO HOLD EACH TYPE OF OUTPUT
	IF object_id('tempdb..#OutputtedSelections') IS NULL
		CREATE TABLE #OutputtedSelections
		(
			PhysicalRowID INT IDENTITY(1,1) NOT NULL,
			AuditID INT NULL,
			AuditItemID INT NULL,
			CaseID INT NULL,
			PartyID INT NULL,
			CaseOutputTypeID INT NULL
		)
		
	-- write back the AuditID
	UPDATE #OutputtedSelections
	SET AuditID = @AuditID
	WHERE AuditID IS NULL

	-- Create AuditItems
	DECLARE @max_AuditItemID INT
	SELECT @max_AuditItemID = ISNULL(MAX(AuditItemID), 0) FROM [$(Sample_Audit)].dbo.AuditItems

	-- Update AuditItemID in table by adding value above to autonumber
	UPDATE #OutputtedSelections
	SET AuditItemID = PhysicalRowID + @max_AuditItemID
	WHERE AuditID = @AuditID

	-- Insert rows from table into AuditItems
	INSERT INTO [$(Sample_Audit)].dbo.AuditItems (AuditItemID, AuditID)
	SELECT AuditItemID, AuditID
	FROM #OutputtedSelections
	WHERE AuditID = @AuditID

	-- Insert rows from table into FileRows
	INSERT INTO [$(Sample_Audit)].dbo.FileRows (AuditItemID, PhysicalRow)
	SELECT AuditItemID, PhysicalRowID
	FROM #OutputtedSelections
	WHERE AuditID = @AuditID

		
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

