CREATE PROCEDURE [OWAPv2].[uspGDPRRighttoRestrictProcessing]
@PartyID [dbo].[PartyID] = NULL, @Validated BIT OUTPUT, @ValidationFailureReason VARCHAR (255) OUTPUT

/*
	Purpose:	OWAP Date of Birth Update

	Version		Date			Developer			Comment
	1.1			2018-04-04		Chris Ledger		BUG 14399 - GDPR Right to Restrict Processing
	1.2			2018-06-28		Chris Ledger		ADD Validation
	1.3			2020-01-21		Chris Ledger		BUG 15372: Fix Hard coded references to databases.
*/

AS

SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	------------------------------------------------------------------------
	-- V1.2 Check params populated correctly
	------------------------------------------------------------------------
	SET @Validated = 0
		
	IF	@PartyID IS NULL
	BEGIN
		SET @ValidationFailureReason = '@PartyID parameter has not been supplied'
		RETURN 0
	END 

	IF	0 = (SELECT COUNT(*) FROM Party.People WHERE PartyID = @PartyID)
	BEGIN
		SET @ValidationFailureReason = 'The supplied PartyID is not found in the People table.'
		RETURN 0
	END 

	SET @Validated = 1
	------------------------------------------------------------------------

	BEGIN TRAN

		--------------------------------------------------------------------------------
		-- ADD PARTIES TO RESTRICT PROCESSING
		--------------------------------------------------------------------------------
		--DROP TABLE #Parties

		CREATE TABLE #Parties
		(	ID INT IDENTITY(1, 1),
			AuditID INT,
			AuditItemID INT,
			PartyID BIGINT
		)

		INSERT  INTO #Parties (PartyID)
		VALUES 
		(@PartyID)
		--------------------------------------------------------------------------------


		--------------------------------------------------------------------------------
		-- LOG AUDITID OF METADATA
		--------------------------------------------------------------------------------
		DECLARE @DateTimeStamp VARCHAR(50) = CONVERT(VARCHAR,CONVERT(DATE,GETDATE())) + '_' + SUBSTRING(CONVERT(VARCHAR,CONVERT(TIME,GETDATE())),1,5)
		DECLARE @FileName VARCHAR(50) = 'GDPR_RestrictProcessing_' + @DateTimeStamp
		DECLARE @FileType VARCHAR(50) = 'GDPR Update'
		DECLARE @FileRowCount INT = (SELECT COUNT(*) FROM #Parties)
		DECLARE @FileChecksum INT = CHECKSUM(@FileName)
		DECLARE @LoadSuccess INT = 1
		--------------------------------------------------------------------------------


		--------------------------------------------------------------------------------
		-- GET THE MAXIMUM AuditID FROM Audit
		--------------------------------------------------------------------------------
		DECLARE @AuditID dbo.AuditID
		SELECT @AuditID = ISNULL(MAX(AuditID), 0) + 1 FROM [$(AuditDB)].dbo.Audit
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- INSERT THE NEW AuditID INTO Audit
		--------------------------------------------------------------------------------
		INSERT INTO [$(AuditDB)].dbo.Audit (AuditID)
		SELECT @AuditID
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- NOW INSERT THE FILE DETAILS
		--------------------------------------------------------------------------------
		INSERT INTO [$(AuditDB)].dbo.Files
		(
			 AuditID
			,FileTypeID
			,FileName
			,FileRowCount
			,ActionDate
		)
		SELECT @AuditID, FileTypeID, @FileName, @FileRowCount, GETDATE() FROM [$(AuditDB)].dbo.FileTypes WHERE FileType = @FileType
		
		INSERT INTO [$(AuditDB)].dbo.IncomingFiles
		(
			 AuditID
			,FileChecksum
			,LoadSuccess
		)
		VALUES (@AuditID, @FileChecksum, @LoadSuccess)

		UPDATE #Parties
		SET AuditID = @AuditID
		--------------------------------------------------------------------------------


		--------------------------------------------------------------------------------
		-- ADD AUDITITEMIDS OF METADATA
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- GET THE NEXT AUDITITEMID
		--------------------------------------------------------------------------------
		DECLARE @MaxAuditItemID INT
		SET @MaxAuditItemID = (SELECT MAX(AuditItemID) FROM [$(AuditDB)].dbo.AuditItems)
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- ASSIGN THE NEXT AUDITITEMIDS IN SEQUENCE TO ANY RECORDS WITHOUT AN AUDITITEMID 
		--------------------------------------------------------------------------------
		UPDATE #Parties
		SET AuditItemID = @MaxAuditItemID + ID
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- WRITE THE NEW AUDITITEMIDS
		--------------------------------------------------------------------------------
		INSERT INTO [$(AuditDB)].dbo.AuditItems
		(
			AuditID
			,AuditItemID
		)
		SELECT 
			AuditID
			,AuditItemID
		FROM #Parties P
		WHERE NOT EXISTS (SELECT 1 FROM [$(AuditDB)].dbo.AuditItems AI WHERE AI.AuditItemID = P.AuditItemID)
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- ADD NON-SOLICITATIONS
		--------------------------------------------------------------------------------
		INSERT	Party.vwDA_NonSolicitations 
		(
			NonSolicitationID,
			NonSolicitationTextID, 
			PartyID,
			FromDate,
			AuditItemID
		)
		
		SELECT 0 AS NonSolicitation,
			(SELECT NonSolicitationTextID FROM dbo.NonSolicitationTexts WHERE NonSolicitationText = 'GDPR Right to Restriction') AS NonSolicitationTextID,
			P.PartyID,
			GETDATE() AS FromDate,
			P.AuditItemID
		FROM #Parties P
		--------------------------------------------------------------------------------

	COMMIT TRAN

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