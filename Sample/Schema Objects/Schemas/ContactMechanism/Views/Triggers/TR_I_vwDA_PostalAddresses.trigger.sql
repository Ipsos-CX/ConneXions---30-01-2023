CREATE TRIGGER ContactMechanism.TR_I_vwDA_PostalAddresses ON ContactMechanism.vwDA_PostalAddresses
INSTEAD OF INSERT

AS

/*
	Purpose:	Handles insert into vwDA_PostalAddresses
				All rows in VWT containing address information should be inserted into view.
				Those that are 'parents' and have not been matched are used to populate ContactMechanism and PostalAddresses tables with the ContactMechanismIDs being written back to the VWT
				All rows are written to the Audit.PostalAddresses table
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_PostalAddresses.TR_I_vwDA_PostalAddresses

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

		-- CREATE VARIABLE TO HOLD THE MAXIMUM CONTACTMECHANISMID
		DECLARE @Max_ContactMechanismID INT

		-- CREATE A TABLE TO STORE THE NEW POSTAL ADDRESS DATA
		DECLARE @PostalAddresses TABLE
		(
			ID INT IDENTITY(1, 1) NOT NULL, 
			AuditItemID BIGINT NOT NULL, 
			ContactMechanismID INT, 
			ContactMechanismTypeID SMALLINT 
		)
		
		-- GET THE NEW (UNMATCHED) UNIQUE POSTAL ADDRESS DATA
		INSERT INTO @PostalAddresses
		(
			AuditItemID, 
			ContactMechanismTypeID
		)
		SELECT DISTINCT
			AddressParentAuditItemID, 
			ContactMechanismTypeID
		FROM INSERTED
		WHERE AuditItemID = AddressParentAuditItemID
		AND ISNULL(ContactMechanismID, 0) = 0

		-- GET THE MAXIMUM CONTACTMECHANISMID
		SELECT @Max_ContactMechanismID = ISNULL(MAX(ContactMechanismID), 0) FROM ContactMechanism.ContactMechanisms

		-- GENERATE THE NEW CONTACTMECHANISMIDS USING THE IDENTITY VALUE
		UPDATE @PostalAddresses
		SET ContactMechanismID = ID + @Max_ContactMechanismID
		

		-- ADD THE NEW CONTACTMECHANISMIDs TO THE ContactMechanisms TABLE (AND AUDIT)
		INSERT INTO ContactMechanism.vwDA_ContactMechanisms
		(
			AuditItemID, 
			ContactMechanismID, 
			ContactMechanismTypeID, 
			Valid
		)
		SELECT DISTINCT
			I.AuditItemID, 
			COALESCE(PA.ContactMechanismID, I.ContactMechanismID), 
			I.ContactMechanismTypeID, 
			CAST(1 AS BIT) AS Valid
		FROM INSERTED I
		LEFT JOIN @PostalAddresses PA ON PA.AuditItemID = I.AddressParentAuditItemID
		ORDER BY I.AuditItemID


		-- ADD THE NEW CONTACTMECHANISMIDs TO THE PostalAddresses TABLE
		INSERT INTO ContactMechanism.PostalAddresses
		(
			ContactMechanismID, 
			BuildingName, 
			SubStreetNumber, 
			SubStreet, 
			StreetNumber, 
			Street, 
			SubLocality, 
			Locality, 
			Town, 
			Region, 
			PostCode, 
			CountryID, 
			AddressChecksum
		)
		SELECT DISTINCT
			PA.ContactMechanismID, 
			I.BuildingName, 
			I.SubStreetNumber, 
			I.SubStreet, 
			I.StreetNumber, 
			I.Street, 
			I.SubLocality, 
			I.Locality, 
			I.Town, 
			I.Region, 
			I.PostCode, 
			I.CountryID, 
			I.AddressChecksum
		FROM @PostalAddresses PA
		INNER JOIN INSERTED I ON PA.AuditItemID = I.AuditItemID
		ORDER BY PA.ContactMechanismID

		-- UPDATE VWT WITH ContactMechanismIDs OF INSERTED POSTAL ADDRESSES
		UPDATE V
		SET V.MatchedODSAddressID = PA.ContactMechanismID
		FROM [$(ETLDB)].dbo.VWT V
		INNER JOIN @PostalAddresses PA ON PA.AuditItemID = V.AddressParentAuditItemID

		-- INSERT ALL THE POSTAL ADDRESSES INTO Audit.PostalAddresses WHERE WE'VE NOT ALREADY LOADED THEM
		INSERT INTO [$(AuditDB)].Audit.PostalAddresses
		(
			AuditItemID, 
			ContactMechanismID, 
			BuildingName, 
			SubStreetAndNumberOrig, 
			SubStreetOrig, 
			SubStreetNumber, 
			SubStreet, 
			StreetAndNumberOrig, 
			StreetOrig, 
			StreetNumber, 
			Street, 
			SubLocality, 
			Locality, 
			Town, 
			Region, 
			PostCode, 
			CountryID, 
			AddressChecksum
		)
		SELECT DISTINCT
			I.AuditItemID,
			COALESCE(PA.ContactMechanismID, I.ContactMechanismID), 
			I.BuildingName, 
			I.SubStreetAndNumberOrig, 
			I.SubStreetOrig, 
			I.SubStreetNumber, 
			I.SubStreet, 
			I.StreetAndNumberOrig, 
			I.StreetOrig, 
			I.StreetNumber, 
			I.Street, 
			I.SubLocality, 
			I.Locality, 
			I.Town, 
			I.Region, 
			I.PostCode, 
			I.CountryID, 
			I.AddressChecksum
		FROM INSERTED I
		LEFT JOIN @PostalAddresses PA ON PA.AuditItemID = I.AddressParentAuditItemID
		LEFT JOIN [$(AuditDB)].Audit.PostalAddresses APA ON APA.AuditItemID = I.AuditItemID
									AND COALESCE(PA.ContactMechanismID, I.ContactMechanismID) = APA.ContactMechanismID
		WHERE APA.AuditItemID IS NULL
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












