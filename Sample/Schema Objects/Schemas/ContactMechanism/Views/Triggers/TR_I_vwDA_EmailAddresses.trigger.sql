CREATE TRIGGER ContactMechanism.TR_I_vwDA_EmailAddresses ON ContactMechanism.vwDA_EmailAddresses
INSTEAD OF INSERT

AS

/*
	Purpose:	Handles insert into vwDA_EmailAddresses
				All columns in VWT containing emails should be inserted into view.
				The ContactMechanismIDs are written back to the VWT
				All rows are written to the Audit.EmailAddresses table
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_vwDA_ElectronicAddresses.TR_I_vwDA_vwDA_ElectronicAddresses
	1.1				06-04-2015		Chris Ross			BUG 12226 - Add in EmailAddressType into Email Address audit table.  Also removed bug where multiple 
																	contact mechanisms for EmailAddress being saved to Audit.
	1.2				11-11-2016		Chris Ledger		Extra filter to stop non inserted rows being audited
	1.3				09-03-2020		Chris Ledger		BUG 18001 - Force JOIN types to avoid NESTED LOOP
	1.4				11-03-2020		Chris Ledger		BUG 16936 - Trim leading/trailing spaces from email addresses
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

		-- DECLARE VARIABLE TO HOLD MAXIMUM ContactMechanismID
		DECLARE @Max_ContactMechanismID INT

		-- GET MAXIMUM ContactMechanismID
		SELECT @Max_ContactMechanismID = ISNULL(MAX(ContactMechanismID), 0) FROM ContactMechanism.ContactMechanisms

		-- CREATE A TABLE TO HOLD THE NEW EMAILS
		DECLARE @EmailAddresses TABLE
		(
			ID INT IDENTITY(1, 1) NOT NULL, 
			ContactMechanismID INT, 
			ContactMechanismTypeID TINYINT, 
			EmailAddress NVARCHAR(510), 
			EmailAddressChecksum INT,
			EmailAddressType VARCHAR(20)
		)

		-- INSERT THE NEW EMAILS TO THE TABLE
		INSERT INTO @EmailAddresses
		(
			ContactMechanismTypeID, 
			EmailAddress, 
			EmailAddressChecksum, 
			EmailAddressType
		)
		SELECT DISTINCT
			I.ContactMechanismTypeID, 
			I.EmailAddress, 
			I.EmailAddressChecksum, 
			I.EmailAddressType
		FROM INSERTED I
		LEFT HASH JOIN ContactMechanism.EmailAddresses EA																-- V1.3
			INNER MERGE JOIN ContactMechanism.ContactMechanisms CM ON EA.ContactMechanismID = CM.ContactMechanismID		-- V1.3
		ON EA.EmailAddress = I.EmailAddress
		AND CM.ContactMechanismTypeID = I.ContactMechanismTypeID
		WHERE EA.ContactMechanismID IS NULL
		AND I.ContactMechanismID = 0
		AND ISNULL(I.EmailAddressChecksum, 0) <> 0

		-- CREATE NEW ContactMechanismID VALUES
		UPDATE @EmailAddresses
		SET ContactMechanismID = ID + @Max_ContactMechanismID
		WHERE ISNULL(ContactMechanismID, 0) = 0
		
				
		-- INSERT NEW CONTACT MECHANISMS (AND AUDIT)
		INSERT INTO ContactMechanism.vwDA_ContactMechanisms
		(
			AuditItemID, 
			ContactMechanismID, 
			ContactMechanismTypeID, 
			Valid
		)
		SELECT DISTINCT
			I.AuditItemID, 
			EA.ContactMechanismID, 
			EA.ContactMechanismTypeID, 
			1 AS Valid
		FROM @EmailAddresses EA
		INNER JOIN INSERTED I ON EA.EmailAddressChecksum = I.EmailAddressChecksum
		ORDER BY I.AuditItemID

		-- INSERT NEW EMAILS
		INSERT INTO ContactMechanism.EmailAddresses
		(
			ContactMechanismID, 
			EmailAddress
		)
		SELECT DISTINCT
			ContactMechanismID, 
			EmailAddress
		FROM @EmailAddresses
		ORDER BY ContactMechanismID
		
		-- UPDATE VWT WITH ContactMechanismIDs OF INSERTED EMAIL ADDRESSES

		-- 'EmailAddress
		UPDATE V
		SET V.MatchedODSEmailAddressID =  EA.ContactMechanismID
		FROM [$(ETLDB)].dbo.VWT V
		INNER JOIN @EmailAddresses EA ON CHECKSUM(ISNULL(LTRIM(RTRIM(V.EmailAddress)), '')) = EA.EmailAddressChecksum	-- V1.4
		WHERE EA.EmailAddressType = 'EmailAddress'
		AND EA.EmailAddressChecksum <> 0

		-- 'PrivEmailAddress
		UPDATE V
		SET V.MatchedODSPrivEmailAddressID =  EA.ContactMechanismID
		FROM [$(ETLDB)].dbo.VWT V
		INNER JOIN @EmailAddresses EA ON CHECKSUM(ISNULL(LTRIM(RTRIM(V.PrivEmailAddress)), '')) = EA.EmailAddressChecksum	-- V1.4
		WHERE EA.EmailAddressType = 'PrivEmailAddress'
		AND EA.EmailAddressChecksum <> 0


		-- INSERT AUDIT ROWS for EmailAddress INTO Audit.EmailAddresses
		INSERT INTO [Sample_Audit].Audit.EmailAddresses
		(
			AuditItemID,
			ContactMechanismID, 
			EmailAddress,
			EmailAddressSource
		)
		SELECT DISTINCT
			I.AuditItemID, 
			V.MatchedODSEmailAddressID, 
			I.EmailAddress,
			I.EmailAddressType
		FROM INSERTED I
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = I.AuditItemID
		LEFT JOIN [$(AuditDB)].Audit.EmailAddresses AEA ON AEA.ContactMechanismID = I.ContactMechanismID
														AND AEA.AuditItemID = I.AuditItemID
														AND AEA.EmailAddressSource = I.EmailAddressType
		WHERE I.EmailAddressType = 'EmailAddress'
		AND AEA.ContactMechanismID IS NULL
		AND ISNULL(I.EmailAddressChecksum, 0) <> 0		--V1.2
		ORDER BY I.AuditItemID

		-- INSERT AUDIT ROWS for PrivEmailAddress INTO Audit.EmailAddresses 
		INSERT INTO [Sample_Audit].Audit.EmailAddresses
		(
			AuditItemID,
			ContactMechanismID, 
			EmailAddress,
			EmailAddressSource
		)
		SELECT DISTINCT
			I.AuditItemID, 
			V.MatchedODSPrivEmailAddressID, 
			I.EmailAddress,
			I.EmailAddressType
		FROM INSERTED I
		INNER JOIN [$(ETLDB)].dbo.VWT V ON V.AuditItemID = I.AuditItemID
		LEFT JOIN [$(AuditDB)].Audit.EmailAddresses AEA ON AEA.ContactMechanismID = I.ContactMechanismID
														AND AEA.AuditItemID = I.AuditItemID
														AND AEA.EmailAddressSource = I.EmailAddressType
		WHERE I.EmailAddressType = 'PrivEmailAddress'
		AND AEA.ContactMechanismID IS NULL
		AND ISNULL(I.EmailAddressChecksum, 0) <> 0		--V1.2
		ORDER BY I.AuditItemID

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
	











