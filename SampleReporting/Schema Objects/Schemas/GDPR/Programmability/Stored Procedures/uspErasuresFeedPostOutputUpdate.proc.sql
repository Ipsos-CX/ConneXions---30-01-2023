CREATE PROCEDURE [GDPR].[uspErasuresFeedPostOutputUpdate]
@FileName VARCHAR (100)
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
	Purpose:	Updates the Sample_Audit.GDPR.GDPRErasuresFeed_Output and GDPR.ErasuresFeedParties tables after we have output the feed.
		
	Version		Date				Developer			Comment
	1.0			02/07/2018			Chris Ross			Created (See BUG 14824)
	1.1			12/07/2018			Chris Ross			BUG14854 - Add in new columns (Market, Survey, FileLoadDate, Responded)
	1.2			15/01/2020			Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/

BEGIN TRAN 

	
		------------------------------------------------------------
		-- Set a single date for all updates
		------------------------------------------------------------
		DECLARE @Datetime DATETIME2
		SET @Datetime = GETDATE()



		------------------------------------------------------------
		-- Update the ErasuresFeedParties file
		------------------------------------------------------------
		UPDATE ef
		SET ef.DateOutput = @Datetime
		FROM GDPR.ErasuresFeedParties ef
		INNER JOIN GDPR.ErasuresFeedBaseTable bt ON bt.PartyID = ef.PartyID
		WHERE ef.DateOutput IS NULL
	
		

		------------------------------------------------------------
		-- Write the Audit Header and File recs
		------------------------------------------------------------
		DECLARE @AuditID	BIGINT,
				@RowCount	INT
		
		SELECT @RowCount = COUNT(*) FROM GDPR.ErasuresFeedBaseTable

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
			(SELECT FileTypeID FROM [$(AuditDB)].dbo.FileTypes WHERE FileType = 'GDPR Erasures Feed Output'),
			@FileName,
			@RowCount,
			@Datetime
		)

		INSERT INTO [$(AuditDB)].dbo.OutgoingFiles (AuditID, OutputSuccess)
		VALUES (@AuditID, 1)

		-- Create AuditItems
		DECLARE @max_AuditItemID INT
		SELECT @max_AuditItemID = ISNULL(MAX(AuditItemID), 0) FROM [$(AuditDB)].dbo.AuditItems

		-- Insert rows into AuditItems
		INSERT INTO [$(AuditDB)].dbo.AuditItems (AuditItemID, AuditID)
		SELECT ID + @max_AuditItemID, @AuditID
		FROM GDPR.ErasuresFeedBaseTable

		-- Insert rows into FileRows
		INSERT INTO [$(AuditDB)].dbo.FileRows (AuditItemID, PhysicalRow)
		SELECT ID + @max_AuditItemID, ID
		FROM GDPR.ErasuresFeedBaseTable


		------------------------------------------------------------
		-- Write the outputs into the audit table
		------------------------------------------------------------
		INSERT INTO [$(AuditDB)].GDPR.GDPRErasuresFeed_Outputs (AuditItemID, PartyID, ErasureDate, LoggingAuditItemID, CaseID, Market, Survey, FileLoadDate, RespondedDate, OutputDate)
		SELECT  ID + @max_AuditItemID AS AuditItemID, 
				bt.PartyID, 
				bt.ErasureDate, 
				bt.AuditItemID AS LoggingAuditItemID, 
				bt.CaseID, 
				Market, 
				Survey, 
				FileLoadDate, 
				RespondedDate,
				@Datetime AS OutputDate
		FROM  GDPR.ErasuresFeedBaseTable bt
		


		
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

