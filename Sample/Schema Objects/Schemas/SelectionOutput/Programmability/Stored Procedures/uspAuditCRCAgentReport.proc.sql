CREATE PROCEDURE [SelectionOutput].[uspAuditCRCAgentReport]
@FileName VARCHAR (255)
AS
SET NOCOUNT ON


---------------------------------------------------------------------------------------------------
--	
--	Change History...
--	
--	Date		Author			Version		Description
--  ----		------			-------		-----------
--	05/05/2016	Eddie Thomas	1.0			Original version

---------------------------------------------------------------------------------------------------

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
		CREATE TABLE #RejectedCases
		(
			PhysicalRowID	INT IDENTITY(1,1) NOT NULL,
			AuditID			INT NULL,
			AuditItemID		INT NULL,
			CaseID			INT NULL,
			PartyID			INT NULL,
			Surname			NVARCHAR(100),
			CoName			NVARCHAR(100),
			Brand			VARCHAR(100),
			Market			NVARCHAR(200),
			AgentCode		VARCHAR(100)
		)

		DECLARE @RowCount INT
		DECLARE @AuditID dbo.AuditID

		INSERT INTO #RejectedCases (CaseID, PartyID, Surname, CoName, Brand, Market, AgentCode)
		SELECT CaseID, PartyID, Surname, CoName, Brand, Market, AgentCode
		FROM SelectionOutput.RejectedCRCCases

		-- get the RowCount
		SET @RowCount = (SELECT COUNT(*) FROM #RejectedCases)

		IF @RowCount > 0
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
				(SELECT FileTypeID FROM [$(AuditDB)].[dbo].[FileTypes] WHERE FileType = 'CRC Uncoded Agent Names'),
				@FileName,
				@RowCount,
				@Date
			)

			INSERT INTO [$(AuditDB)].[dbo].[OutgoingFiles] (AuditID, OutputSuccess)
			VALUES (@AuditID, 1)

			-- write back the AuditID
			UPDATE #RejectedCases
			SET AuditID = @AuditID
			WHERE AuditID IS NULL

			-- Create AuditItems
			DECLARE @max_AuditItemID INT
			SELECT @max_AuditItemID = ISNULL(MAX(AuditItemID), 0) FROM [$(AuditDB)].dbo.AuditItems

			-- Update AuditItemID in table by adding value above to autonumber
			UPDATE #RejectedCases
			SET AuditItemID = PhysicalRowID + @max_AuditItemID
			WHERE AuditID = @AuditID

			-- Insert rows from table into AuditItems
			INSERT INTO [$(AuditDB)].[dbo].[AuditItems] (AuditItemID, AuditID)
			SELECT AuditItemID, AuditID
			FROM #RejectedCases
			WHERE AuditID = @AuditID

			-- Insert rows from table into FileRows
			INSERT INTO [$(AuditDB)].[dbo].[FileRows] (AuditItemID, PhysicalRow)
			SELECT AuditItemID, PhysicalRowID
			FROM #RejectedCases
			WHERE AuditID = @AuditID

			INSERT INTO [$(AuditDB)].[audit].[RejectedCRCCases]
			(
				[AuditID], 
				[AuditItemID], 
				[PartyID],
				[CaseID],
				[Surname],
				[CoName],
				[Brand],
				[Market],
				[AgentCode],
				[ReportDate]
			)
			SELECT 
				r.AuditID,
				r.AuditItemID,	
				r.PartyID,
				r.CaseID,
				r.Surname,
				r.CoName,
				r.Brand,
				r.Market,
				r.AgentCode,
				@Date
				
			FROM #RejectedCases r
			ORDER BY r.AuditItemID

		END

		-- DROP THE TEMPORARY TABLE
		DROP TABLE #RejectedCases
		
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

	EXEC [$(ErrorDB)].[dbo].[uspLogDatabaseError]
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