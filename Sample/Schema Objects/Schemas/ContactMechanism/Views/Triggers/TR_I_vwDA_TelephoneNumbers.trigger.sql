CREATE TRIGGER ContactMechanism.TR_I_vwDA_TelephoneNumbers ON ContactMechanism.vwDA_TelephoneNumbers
INSTEAD OF INSERT

AS

/*
	Purpose:	Handles insert into vwDA_TelephoneNumber
				All columns in VWT containing telecoms numbers should be inserted into view.
				The ContactMechanismIDs are written back to the VWT
				All rows are written to the Audit.TelephoneNumbers table
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_TelecommunicationsNumbers.TR_I_vwDA_TelecommunicationsNumbers
	1.1				23/11/2015		Chris Ross			BUG 12081 - Added in ContactMechanismTypeID to lookup and VWT write back.
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

		-- CREATE TABLE TO HOLD ALL DATA FROM INSERTED
		CREATE TABLE #TelephoneNumbers
		(
			ID INT IDENTITY(1, 1) NOT NULL, 
			ContactMechanismID INT, 
			ContactMechanismTypeID TINYINT, 
			ContactNumber NVARCHAR(70), 
			TelephoneType VARCHAR(100)
		)

		-- INSERT ROWS FROM INSERTED INTO TABLE VARIABLE
		INSERT INTO #TelephoneNumbers
		(
			ContactMechanismID,
			ContactMechanismTypeID, 
			ContactNumber, 
			TelephoneType
		)
		SELECT DISTINCT
			MIN(ContactMechanismID),
			ContactMechanismTypeID, 
			ContactNumber, 
			TelephoneType
		FROM INSERTED	
		GROUP BY
			ContactMechanismTypeID, 
			ContactNumber, 
			TelephoneType
		ORDER BY MIN(ContactMechanismID)


		-- CREATE NEW ContactMechanismID VALUES
		UPDATE #TelephoneNumbers
		SET ContactMechanismID = ID + @Max_ContactMechanismID
		WHERE ISNULL(ContactMechanismID, 0) = 0


		-- INSERT FROM TABLE VARIABLE INTO vwDA_ContactMechanisms
		INSERT INTO ContactMechanism.vwDA_ContactMechanisms
		(
			AuditItemID, 
			ContactMechanismID, 
			ContactMechanismTypeID, 
			Valid
		)
		SELECT DISTINCT
			I.AuditItemID, 
			T.ContactMechanismID, 
			I.ContactMechanismTypeID, 
			I.Valid
		FROM #TelephoneNumbers T
		INNER JOIN INSERTED I ON T.ContactNumber = I.ContactNumber
							AND T.ContactMechanismTypeID = I.ContactMechanismTypeID
		ORDER BY I.AuditItemID


		-- INSERT INTO TelephoneNumbers
		INSERT INTO ContactMechanism.TelephoneNumbers
		(
			ContactMechanismID, 
			ContactNumber
		)
		SELECT DISTINCT
			T.ContactMechanismID,
			coalesce(replace(I.ContactNumber,char(10),''),replace(I.contactnumber,char(13),''))
		FROM #TelephoneNumbers T
		INNER JOIN INSERTED I on T.ContactNumber = I.ContactNumber
		LEFT JOIN ContactMechanism.TelephoneNumbers TN ON TN.ContactMechanismID = T.ContactMechanismID
		WHERE TN.ContactMechanismID IS NULL
		ORDER BY T.ContactMechanismID
			

		-- INSERT ALL ROWS INTO Audit.TelephoneNumbers
		INSERT INTO [$(AuditDB)].Audit.TelephoneNumbers
		(
			AuditItemID,
			ContactMechanismID, 
			ContactNumber
		)
		SELECT DISTINCT
			I.AuditItemID, 
			T.ContactMechanismID, 	
			I.ContactNumber
		FROM #TelephoneNumbers T
		INNER JOIN INSERTED I ON T.ContactNumber = I.ContactNumber
		LEFT JOIN [$(AuditDB)].Audit.TelephoneNumbers ATN ON ATN.ContactMechanismID = T.ContactMechanismID
										AND ATN.AuditItemID = I.AuditItemID
		WHERE ATN.ContactMechanismID IS NULL
		ORDER BY I.AuditItemID	


		-- UPDATE VWT WITH CONTACTMECHANISMIDS OF INSERTED TELECOMMUNICATIONS NUMBERS

		-- Tel
		UPDATE V
		SET V.MatchedODSTelID = ATN.ContactMechanismID
		FROM [$(ETLDB)].dbo.VWT V
		INNER JOIN [$(AuditDB)].Audit.TelephoneNumbers ATN ON ATN.AuditItemID = V.AuditItemID
														AND ATN.ContactNumber = V.Tel
		INNER JOIN ContactMechanism.ContactMechanisms cm ON cm.ContactMechanismID = atn.ContactMechanismID
														AND cm.ContactMechanismTypeID =  (SELECT ContactMechanismTypeID 
																							FROM ContactMechanism.ContactMechanismTypes 
																							WHERE ContactMechanismType = 'Phone (landline)') 
		WHERE ISNULL(V.MatchedODSTelID, 0) = 0

		-- Priv Tel
		UPDATE V
		SET V.MatchedODSPrivTelID = ATN.ContactMechanismID
		FROM [$(ETLDB)].dbo.VWT V
		INNER JOIN [$(AuditDB)].Audit.TelephoneNumbers ATN ON ATN.AuditItemID = V.AuditItemID
														AND ATN.ContactNumber = V.PrivTel
		INNER JOIN ContactMechanism.ContactMechanisms cm ON cm.ContactMechanismID = atn.ContactMechanismID
														AND cm.ContactMechanismTypeID =  (SELECT ContactMechanismTypeID 
																							FROM ContactMechanism.ContactMechanismTypes 
																							WHERE ContactMechanismType = 'Phone (landline)') 
		WHERE ISNULL(V.MatchedODSPrivTelID, 0) = 0

		-- Bus Tel
		UPDATE V
		SET V.MatchedODSBusTelID = ATN.ContactMechanismID
		FROM [$(ETLDB)].dbo.VWT V
		INNER JOIN [$(AuditDB)].Audit.TelephoneNumbers ATN ON ATN.AuditItemID = V.AuditItemID
														AND ATN.ContactNumber = V.BusTel
		INNER JOIN ContactMechanism.ContactMechanisms cm ON cm.ContactMechanismID = atn.ContactMechanismID
														AND cm.ContactMechanismTypeID =  (SELECT ContactMechanismTypeID 
																							FROM ContactMechanism.ContactMechanismTypes 
																							WHERE ContactMechanismType = 'Phone (landline)') 
		WHERE ISNULL(V.MatchedODSBusTelID, 0) = 0

		-- MobileTel
		UPDATE V
		SET V.MatchedODSMobileTelID = ATN.ContactMechanismID
		FROM [$(ETLDB)].dbo.VWT V
		INNER JOIN [$(AuditDB)].Audit.TelephoneNumbers ATN ON ATN.AuditItemID = V.AuditItemID
														AND ATN.ContactNumber = V.MobileTel
		INNER JOIN ContactMechanism.ContactMechanisms cm ON cm.ContactMechanismID = atn.ContactMechanismID
														AND cm.ContactMechanismTypeID =  (SELECT ContactMechanismTypeID 
																							FROM ContactMechanism.ContactMechanismTypes 
																							WHERE ContactMechanismType = 'Phone (mobile)') 
		WHERE ISNULL(V.MatchedODSMobileTelID, 0) = 0

		-- PrivMobileTel
		UPDATE V
		SET V.MatchedODSPrivMobileTelID = ATN.ContactMechanismID
		FROM [$(ETLDB)].dbo.VWT V
		INNER JOIN [$(AuditDB)].Audit.TelephoneNumbers ATN ON ATN.AuditItemID = V.AuditItemID
														AND ATN.ContactNumber = V.PrivMobileTel
		INNER JOIN ContactMechanism.ContactMechanisms cm ON cm.ContactMechanismID = atn.ContactMechanismID
														AND cm.ContactMechanismTypeID =  (SELECT ContactMechanismTypeID 
																							FROM ContactMechanism.ContactMechanismTypes 
																							WHERE ContactMechanismType = 'Phone (mobile)') 
		WHERE ISNULL(V.MatchedODSPrivMobileTelID, 0) = 0
	
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
	



