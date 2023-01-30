CREATE PROCEDURE [OWAPv2].[uspUpdateDateofBirth]
@PartyID [dbo].[PartyID] = NULL, @NewBirthDate DATETIME2(7) = NULL, @Validated BIT OUTPUT, @ValidationFailureReason VARCHAR (255) OUTPUT

/*
	Purpose:	OWAP Date of Birth Update

	Version		Date			Developer			Comment
	1.1			2018-04-04		Chris Ledger		BUG 14399 - GDPR Update Date of Birth
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

	--------------------------------------------------------------------------------
	-- V1.2 Check parameters populated correctly
	--------------------------------------------------------------------------------
	SET @Validated = 0
		
	IF	@PartyID IS NULL
	BEGIN
		SET @ValidationFailureReason = '@PartyID parameter has not been supplied'
		RETURN 0
	END 

	IF	@NewBirthDate IS NULL
	BEGIN
		SET @ValidationFailureReason = '@NewBirthDate parameter has not been supplied'
		RETURN 0
	END 

	IF	0 = (SELECT COUNT(*) FROM Party.People WHERE PartyID = @PartyID)
	BEGIN
		SET @ValidationFailureReason = 'The supplied PartyID is not found in the People table.'
		RETURN 0
	END 

	SET @Validated = 1
	--------------------------------------------------------------------------------

	BEGIN TRAN
		
		--------------------------------------------------------------------------------
		-- LOG AUDITID OF METADATA
		--------------------------------------------------------------------------------
		DECLARE @DateTimeStamp VARCHAR(50) = CONVERT(VARCHAR,CONVERT(DATE,GETDATE())) + '_' + SUBSTRING(CONVERT(VARCHAR,CONVERT(TIME,GETDATE())),1,5)
		DECLARE @FileName VARCHAR(50) = 'GDPR_UpdateDOB_' + @DateTimeStamp
		DECLARE @FileType VARCHAR(50) = 'GDPR Update'
		DECLARE @FileRowCount INT = 1
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
		--------------------------------------------------------------------------------


		--------------------------------------------------------------------------------
		-- ADD AUDITITEMIDS OF METADATA
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- GET THE NEXT AUDITITEMID
		--------------------------------------------------------------------------------
		DECLARE @AuditItemID INT
		SELECT @AuditItemID = MAX(AuditItemID) + 1 FROM [$(AuditDB)].dbo.AuditItems 
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- WRITE THE NEW AUDITITEMIDS
		--------------------------------------------------------------------------------
		INSERT INTO [$(AuditDB)].dbo.AuditItems
		(
			AuditID
			,AuditItemID
		)
		VALUES (@AuditID, @AuditItemID)
		--------------------------------------------------------------------------------


		--------------------------------------------------------------------------------
		-- UPDATE DATE OF BIRTH
		--------------------------------------------------------------------------------
		UPDATE P SET P.BirthDate = @NewBirthDate
		FROM Party.People P
		WHERE P.PartyID = @PartyID
		--------------------------------------------------------------------------------


		--------------------------------------------------------------------------------
		-- AUDIT THE NEW DATE OF BIRTH
		--------------------------------------------------------------------------------
		INSERT INTO [$(AuditDB)].Audit.People
		(
			AuditItemID, 
			PartyID, 
			FromDate, 
			TitleID, 
			Title, 
			Initials, 
			FirstName, 
			MiddleName, 
			LastName, 
			SecondLastName, 
			GenderID, 
			BirthDate
		)
		SELECT	@AuditItemID,
			PartyID, 
			FromDate, 
			P.TitleID, 
			Title, 
			Initials, 
			FirstName, 
			MiddleName, 
			LastName, 
			SecondLastName, 
			GenderID, 
			BirthDate
		FROM Party.People P
		INNER JOIN Party.Titles T ON P.TitleID = T.TitleID
		WHERE P.PartyID = @PartyID
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
