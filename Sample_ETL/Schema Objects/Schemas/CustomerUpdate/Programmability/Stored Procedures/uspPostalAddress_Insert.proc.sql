CREATE PROCEDURE CustomerUpdate.uspPostalAddress_Insert

AS

/*
	Purpose:	Insert into PostalAddresses the data from the customer update and load into Audit

	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created from [Prophet-ETL].dbo.uspIP_CUSTOMERUPDATE_ODSInsert_PostalAddress
	1.1				06/08/2015		Eddie Thomas		BUG 11719: Customer Update Address Checksum/Matching issue
	1.2				18/04/2018		Chris Ledger		BUG 14468: Fix bug where CountryID supplied is 0

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
	
		-- get the postal address contact mechanism type ID
		-- and home address purpose type ID
		DECLARE @PostalAddress SMALLINT
		DECLARE @HomeAddress SMALLINT
		
		SELECT @PostalAddress = ContactMechanismTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Postal Address'
		SELECT @HomeAddress = ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Main home address'

		-- Check the CaseID and PartyID combination is valid and CountryID is present
		UPDATE CUPA
		SET CUPA.CasePartyCombinationValid = 1
		FROM CustomerUpdate.PostalAddress CUPA
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CUPA.CaseID
																	AND AEBI.PartyID = CUPA.PartyID

		INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON CUPA.CountryID = C.CountryID		-- V1.2
		-- PostalAddresses
		INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_PostalAddresses
		(
			AuditItemID, 
			AddressParentAuditItemID, 
			ContactMechanismID, 
			ContactMechanismTypeID, 
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
			AddressChecksum					-- V1.1
		)
		SELECT 
			AuditItemID, 
			ParentAuditItemID AS AddressParentAuditItemID, 
			ISNULL(ContactMechanismID, 0) AS ContactMechanismID,
			@PostalAddress AS ContactMechanismTypeID,
			ISNULL(BuildingName, '') AS BuildingName, 
			ISNULL(SubStreetAndNumber, '') AS SubStreetAndNumberOrig, 
			'' AS SubStreetOrig, 
			ISNULL(SubStreetNumber, '') AS SubStreetNumber, 
			COALESCE(SubStreet, SubStreetAndNumber, '') AS SubStreet, 
			ISNULL(StreetAndNumber, '') AS StreetAndNumberOrig, 
			'' AS StreetOrig, 
			ISNULL(StreetNumber, '') AS StreetNumber, 
			COALESCE(Street, StreetAndNumber, '') AS Street, 
			ISNULL(SubLocality, '') AS SubLocality, 
			ISNULL(Locality, '') AS Locality, 
			ISNULL(Town, '') AS Town, 
			ISNULL(Region, '') AS Region, 
			ISNULL(PostCode, '') AS PostCode, 
			CountryID,
			dbo.udfGenerateAddressChecksum(
											ISNULL(BuildingName, ''),								-- V1.1
											ISNULL(SubStreetAndNumber, ''),							-- V1.1
											COALESCE(SubStreet, SubStreetAndNumber, ''),			-- V1.1
											ISNULL(StreetNumber, '') ,								-- V1.1
											COALESCE(Street, StreetAndNumber, ''),					-- V1.1
											ISNULL(SubLocality, ''),								-- V1.1
											ISNULL(Locality, ''),									-- V1.1
											ISNULL(Town, ''),										-- V1.1
											ISNULL(Region, ''),										-- V1.1
											ISNULL(PostCode, ''),									-- V1.1
											CountryID												-- V1.1
										) AS AddressChecksum										-- V1.1
		FROM CustomerUpdate.PostalAddress
		WHERE CasePartyCombinationValid = 1


		-- get the ContactMechanismIDs generated
		UPDATE CUPA
		SET CUPA.ContactMechanismID = APA.ContactMechanismID
		FROM CustomerUpdate.PostalAddress CUPA
		INNER JOIN [$(AuditDB)].Audit.PostalAddresses APA ON APA.AuditItemID = CUPA.AuditItemID


		-- PartyPostalAddresses (which inserts into PartyContactMechanisms)
		INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_PartyPostalAddresses
		(
			AuditItemID,
			ContactMechanismID,
			PartyID,
			FromDate,
			ContactMechanismPurposeTypeID
		)
		SELECT
			AuditItemID,
			ContactMechanismID,
			PartyID,
			GETDATE(),
			@HomeAddress AS ContactMechanismPurposeTypeID -- Main Home Address
		FROM CustomerUpdate.PostalAddress
		WHERE CasePartyCombinationValid = 1

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




