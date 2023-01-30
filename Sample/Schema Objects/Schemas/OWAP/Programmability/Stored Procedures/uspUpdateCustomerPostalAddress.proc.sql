CREATE PROCEDURE [OWAP].[uspUpdateCustomerPostalAddress]
	@SessionID [dbo].[SessionID], 
	@AuditID [dbo].[AuditID], 
	@UserPartyRoleID [dbo].[PartyRoleID], 
	@PartyID [dbo].[PartyID], 
	@BuildingName [dbo].[AddressText], 
	@SubStreetNumber [dbo].[AddressNumberText], 
	@SubStreet [dbo].[AddressText], 
	@StreetNumber [dbo].[AddressNumberText], 
	@Street [dbo].[AddressText], 
	@SubLocality [dbo].[AddressText], 
	@Locality [dbo].[AddressText], 
	@Town [dbo].[AddressText], 
	@Region [dbo].[AddressText], 
	@PostCode [dbo].[Postcode], 
	@CountryID [dbo].[CountryID], 
	@ErrorCode INT OUTPUT
AS

/*
	Purpose:	Insert the new/correct postal address into PostalAddresses with the data supplied from the OWAP

	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created
	1.1				27/Apr/2012		Pardip Mudhar		Enhanced it further to upadate address checksum and link to PartyContactMechanism
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
	
		DECLARE @AuditItemID dbo.AuditItemID
		DECLARE @ActionDate DATETIME2
		DECLARE @UserPartyID dbo.PartyID
		DECLARE @UserRoleTypeID dbo.RoleTypeID
		DECLARE @ContactMechanismID dbo.ContactMechanismID
		
		SET @ActionDate = GETDATE()
		
		-- GET THE USER DETAILS
		SELECT
			@UserPartyID = PR.PartyID,
			@UserRoleTypeID = PR.RoleTypeID
		FROM Party.PartyRoles PR
		INNER JOIN OWAP.Users U ON U.PartyID = PR.PartyID AND U.RoleTypeID = PR.RoleTypeID
		WHERE PR.PartyRoleID = @UserPartyRoleID
		
		-- AUDIT THE ACTION AND GET THE RESULTANT AuditItemID
		EXEC OWAP.uspAuditAction @AuditID, @ActionDate, @UserPartyID, @UserRoleTypeID, @AuditItemID OUTPUT, @ErrorCode OUTPUT
		
		-- ADD THE POSTAL ADDRESS
		INSERT INTO ContactMechanism.vwDA_PostalAddresses
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
			CountryID
		)
		SELECT
			 @AuditItemID AS AuditItemID
			,@AuditItemID AS AddressParentAuditItemID
			,0 AS ContactMechanismID
			,ContactMechanismTypeID
			,ISNULL(@BuildingName, '') AS BuildingName
			,'' AS SubStreetAndNumberOrig
			,'' AS SubStreetOrig
			,ISNULL(@SubStreetNumber, '') AS SubStreetNumber
			,ISNULL(@SubStreet, '') AS SubStreet
			,'' AS StreetAndNumberOrig
			,'' AS StreetOrig
			,ISNULL(@StreetNumber, '') AS StreetNumber
			,ISNULL(@Street, '') AS Street
			,ISNULL(@SubLocality, '') AS SubLocality
			,ISNULL(@Locality, '') AS Locality
			,ISNULL(@Town, '') AS Town
			,ISNULL(@Region, '') AS Region
			,ISNULL(@PostCode, '') AS PostCode
			,ISNULL(@CountryID, '') AS CountryID
		FROM ContactMechanism.ContactMechanismTypes
		WHERE ContactMechanismType = 'Postal Address'
		
		SELECT @ContactMechanismID = MAX(cm.ContactMechanismID)
		FROM [$(AuditDB)].Audit.ContactMechanisms cm
		WHERE AuditItemID = @AuditItemID
		
		INSERT ContactMechanism.vwDA_PartyContactMechanisms
		(
			AuditItemID,
			ContactMechanismID,
			PartyID,
			FromDate,
			ContactMechanismPurposeTypeID,
			RoleTypeID
		)	
		SELECT 
			@AUDITITEMID,
			@CONTACTMECHANISMID,
			@PARTYID,
			GETDATE(),
			1,
			NULL
		/*
			The trigger is not updating the address checksum and this is why it being updated here manually
		*/
		UPDATE PA
		SET PA.AddressChecksum = [Sample_ETL].dbo.udfGenerateAddressChecksum(PA.BuildingName, PA.SubStreetNumber, PA.SubStreet, PA.StreetNumber, PA.Street, PA.SubLocality, PA.Locality, PA.Town, PA.Region, PA.PostCode, PA.CountryID)
		FROM	[$(AuditDB)].Audit.PostalAddresses APA,
				ContactMechanism.PostalAddresses PA
		WHERE APA.AuditItemID = @AuditItemID
		AND PA.ContactMechanismID = @ContactMechanismID
		AND APA.ContactMechanismID = PA.ContactMechanismID

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

