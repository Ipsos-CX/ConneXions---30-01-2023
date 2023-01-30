CREATE TRIGGER [Stage].[TR_I_FIMSBlackListEmail] ON Stage.FIMsBlackListEmail
AFTER INSERT

AS

/*
	Purpose:	Handles insert into Stage.FIMsBlackListEmail.
				Identifies new emails to black list
				

	
	Release			Version			Date			Developer			Comment
	LIVE				1.0			2022-05-03		Ben King 		TASK 866 - 19490 - Add JLR Employees to the Excluded Email list

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	
			--UPDATE EXISTING CONTACT ID'S FOR EMAILS ALREADY LOADED
			UPDATE	F
			SET		F.ContactMechanismID = EA.ContactMechanismID
			FROM	Stage.FIMsBlackListEmail F
			INNER JOIN Match.vwEmailAddresses EA ON EA.EmailAddress = (F.Email)		
			WHERE	ISNULL(LTRIM(RTRIM(F.Email)), '') <> '' 


			/*
			*******************************************************************************************************************
			LOAD NEW EMAILS INTO SYSTEM BEFORE BLACK LISTING

			- START -
			*******************************************************************************************************************
			*/

			-- DECLARE VARIABLE TO HOLD MAXIMUM ContactMechanismID
			DECLARE @Max_ContactMechanismID INT

			-- GET MAXIMUM ContactMechanismID
			SELECT @Max_ContactMechanismID = ISNULL(MAX(ContactMechanismID), 0) FROM [$(SampleDB)].ContactMechanism.ContactMechanisms

			-- CREATE A TABLE TO HOLD THE NEW EMAILS
			DECLARE @EmailAddresses TABLE
				(
					ID INT IDENTITY(1, 1) NOT NULL, 
					ContactMechanismID INT, 
					ContactMechanismTypeID TINYINT, 
					EmailAddress NVARCHAR(510), 
					EmailAddressChecksum INT,
					EmailAddressType VARCHAR(20),
					AuditItemID dbo.AuditItemID NULL
				)

			-- INSERT THE NEW EMAILS TO THE TABLE
			INSERT INTO @EmailAddresses
				(
					ContactMechanismTypeID, 
					EmailAddress, 
					EmailAddressChecksum, 
					EmailAddressType,
					AuditItemID
				)
			SELECT DISTINCT
					F.ContactMechanismTypeID, 
					F.Email, 
					CHECKSUM(Email) AS EmailAddressChecksum, 
					NULL AS EmailAddressType, -- we pass in null for this parameter as this is only used to write the ContactMechanismID back to the VWT which we are not using
					F.AuditItemID
			FROM	Stage.FIMSBlackListEmail F
			WHERE	F.Email IS NOT NULL
			AND		F.ContactMechanismID IS NULL


			-- CREATE NEW ContactMechanismID VALUES
			UPDATE	@EmailAddresses
			SET		ContactMechanismID = ID + @Max_ContactMechanismID
			WHERE	ISNULL(ContactMechanismID, 0) = 0
		
				
			-- INSERT NEW CONTACT MECHANISMS (AND AUDIT)
			INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_ContactMechanisms
				(
					AuditItemID, 
					ContactMechanismID, 
					ContactMechanismTypeID, 
					Valid
				)
			SELECT DISTINCT
					EA.AuditItemID, 
					EA.ContactMechanismID, 
					EA.ContactMechanismTypeID, 
					0 AS Valid --???
			FROM	@EmailAddresses EA
			ORDER BY EA.AuditItemID


			-- INSERT NEW EMAILS
			INSERT INTO [$(SampleDB)].ContactMechanism.EmailAddresses
				(
					ContactMechanismID, 
					EmailAddress
				)
			SELECT DISTINCT
					ContactMechanismID, 
					EmailAddress
			FROM	@EmailAddresses
			ORDER BY ContactMechanismID
		
			
			-- INSERT AUDIT ROWS for EmailAddress INTO Audit.EmailAddresses
			INSERT INTO [$(AuditDB)].Audit.EmailAddresses
				(
					AuditItemID,
					ContactMechanismID, 
					EmailAddress,
					EmailAddressSource
				)
			SELECT DISTINCT
					E.AuditItemID, 
					E.ContactMechanismID, 
					E.EmailAddress,
					E.EmailAddressType
			FROM	@EmailAddresses E
			ORDER BY E.AuditItemID

			/*
			*******************************************************************************************************************
			- END -
			*******************************************************************************************************************
			*/


			--SECOND PASS TO UPDATE NEW CONTACT ID'S
			UPDATE	F
			SET		F.ContactMechanismID = EA.ContactMechanismID
			FROM	Stage.FIMSBlackListEmail F
			INNER JOIN Match.vwEmailAddresses EA ON EA.EmailAddress = F.Email		
			WHERE ISNULL(LTRIM(RTRIM(F.Email)), '') <> '' 


			--CHECK WHAT HAVE ALREADY BEEN BLACK LISTED
			UPDATE	F
			SET		F.AlreadyExists = 1
			FROM	Stage.FIMSBlackListEmail F
			INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistStrings BS ON F.Email = BS.BlacklistString


			--BLACK LIST EMAILS - STEP 1
			INSERT INTO [$(SampleDB)].ContactMechanism.BlacklistStrings ([BlacklistString], [Operator], [BlacklistTypeID], [FromDate])
			SELECT DISTINCT
					F.Email AS BlacklistString,
					F.Operator,
					F.BlacklistTypeID,
					F.FromDate
			FROM	Stage.FIMSBlackListEmail F
			WHERE	F.AlreadyExists IS NULL
			AND		F.Email IS NOT NULL


			--GET LATEST BLACKLISTED ID'S
			UPDATE	F
			SET		F.BlacklistStringID = BS.BlacklistStringID
			FROM	Stage.FIMSBlackListEmail F
			INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistStrings BS ON F.Email = BS.BlacklistString


			--BLACK LIST EMAILS - STEP 2
			INSERT INTO [$(SampleDB)].ContactMechanism.BlacklistContactMechanisms ([ContactMechanismID], [ContactMechanismTypeID], [BlacklistStringID], [FromDate])
			SELECT DISTINCT
					F.ContactMechanismID,
					F.ContactMechanismTypeID,
					F.BlacklistStringID,
					F.FromDate
			FROM	Stage.FIMSBlackListEmail F
			WHERE	F.AlreadyExists IS NULL
			AND		F.Email IS NOT NULL

	
			--AUDIT BLACK LISTED EMAILS
			INSERT INTO [$(AuditDB)].Audit.BlackListEmail
				(
					AuditID,
					AuditItemID,
					PhysicalRowID,
					Email,
					Operator,
					BlacklistTypeID,
					FromDate,
					ContactMechanismID,
					ContactMechanismTypeID,
					BlacklistStringID,
					AlreadyExists
				)
			SELECT 
					F.AuditID,
					F.AuditItemID,
					F.PhysicalRowID,
					F.Email,
					F.Operator,
					F.BlacklistTypeID,
					F.FromDate,
					F.ContactMechanismID,
					F.ContactMechanismTypeID,
					F.BlacklistStringID,
					F.AlreadyExists
			FROM	Stage.FIMSBlackListEmail F
			WHERE	F.AlreadyExists IS NULL
			AND		F.Email IS NOT NULL

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
GO
