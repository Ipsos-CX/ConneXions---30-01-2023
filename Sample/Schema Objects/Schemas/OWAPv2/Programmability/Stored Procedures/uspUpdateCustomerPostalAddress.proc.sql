CREATE PROCEDURE [OWAPv2].[uspUpdateCustomerPostalAddress]
@SessionID [dbo].[SessionID]=null, @AuditID [dbo].[AuditID]=null, @UserPartyRoleID [dbo].[PartyRoleID]=null, @PartyID [dbo].[PartyID], @BuildingName [dbo].[AddressText]=null, @SubStreetNumber [dbo].[AddressNumberText]=null, @SubStreet [dbo].[AddressText]=null, @StreetNumber [dbo].[AddressNumberText] =null, @Street [dbo].[AddressText], @SubLocality [dbo].[AddressText] =null, @Locality [dbo].[AddressText]=null, @Town [dbo].[AddressText], @Region [dbo].[AddressText]=null, @PostCode [dbo].[Postcode]=null, @CountryID [dbo].[CountryID], @ErrorCode INT OUTPUT
AS

/*
	Purpose:	OWAP Postal Address Update

	Version		Date			Developer			Comment
	1.1			2017-03-02		Chris Ledger		BUG 13653 - Add Japan Update to CaseContactMechanismID and CaseDetails
	1.2			2017-03-07		Chris Ledger		BUG 13653 - Correct SubStreetNumber and SubStreet Passed as 100
	1.3			2017-03-14		Chris Ledger		BUG 13653 - Change to use @ContactMechanismID instead of MAX(ContactMechanismID)
	1.4			2020-01-21		Chris Ledger		BUG 15372 - Fix Hard coded references to databases.	
*/

SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	--CHECK IF POSTAL ADDRESS ALREADY EXISTS
	DECLARE @chkSum BIGINT = 0 

	Declare @ActiveAddress			[dbo].[ContactMechanismID] =0,
			@CurrentBuildingName	[dbo].[AddressText], 
			@CurrentSubStreetNumber [dbo].[AddressNumberText], 
			@CurrentSubStreet		[dbo].[AddressText], 
			@CurrentStreetNumber	[dbo].[AddressNumberText], 
			@CurrentStreet			[dbo].[AddressText],
			@CurrentSubLocality		[dbo].[AddressText],
			@CurrentLocality		[dbo].[AddressText],
			@CurrentTown			[dbo].[AddressText],
			@CurrentRegion			[dbo].[AddressText],
			@CurrentPostCode		[dbo].[Postcode],
			@CurrentCountryID		[dbo].[CountryID]


	SELECT	@ActiveAddress			= pba.ContactMechanismID,
			@CurrentBuildingName	= pa.BuildingName, 
			@CurrentSubStreetNumber = pa.SubStreetNumber, 
			@CurrentSubStreet		= pa.SubStreet, 
			@CurrentStreetNumber	= pa.StreetNumber, 
			@CurrentStreet			= pa.Street,
			@CurrentSubLocality		= pa.SubLocality,
			@CurrentLocality		= pa.Locality,
			@CurrentTown			= pa.Town,
			@CurrentRegion			= pa.Region,
			@CurrentPostCode		= pa.PostCode,
			@CurrentCountryID		= pa.CountryID
	
	FROM Meta.PartyBestPostalAddresses	pba
	INNER JOIN	ContactMechanism.PartyContactMechanisms pcm ON	pba.ContactMechanismID	= pcm.ContactMechanismID AND
																pba.PartyID				= pcm.PartyID
	INNER JOIN	ContactMechanism.PostalAddresses		pa	ON	pba.ContactMechanismID = pa.ContactMechanismID
	WHERE		PCM.PartyID = @PartyID

	--NO USUAL POSTAL ADDRESS IN Meta.PartyBestPostalAddresses, GET THE LAST ASSOCIATED ADDRESS FOR THE PARTY
	IF ISNULL(@ActiveAddress,0) = 0
	BEGIN
	
		SELECT	@ActiveAddress			= t.ContactMechanismID,
				@CurrentBuildingName	= pa.BuildingName, 
				@CurrentSubStreetNumber = pa.SubStreetNumber, 
				@CurrentSubStreet		= pa.SubStreet, 
				@CurrentStreetNumber	= pa.StreetNumber, 
				@CurrentStreet			= pa.Street,
				@CurrentSubLocality		= pa.SubLocality,
				@CurrentLocality		= pa.Locality,
				@CurrentTown			= pa.Town,
				@CurrentRegion			= pa.Region,
				@CurrentPostCode		= pa.PostCode,
				@CurrentCountryID		= pa.CountryID
	
		FROM	ContactMechanism.PostalAddresses   pa	
		INNER JOIN 
		(		
			SELECT		MAX(pa.ContactMechanismID)	ContactMechanismID
			FROM		ContactMechanism.PartyContactMechanisms pcm 
			INNER JOIN	ContactMechanism.PostalAddresses		pa	ON	PCM.ContactMechanismID = pa.ContactMechanismID
			WHERE		PCM.PartyID = @PartyID
	
		)	t ON	PA.ContactMechanismID = t.ContactMechanismID
	END


	--CHECK IF ANY OF THE ADDRESS DETAILS HAVE CHANGED
	IF	ISNULL(@BuildingName,'') <> @CurrentBuildingName OR
		--ISNULL(@SubStreetNumber,'') <> @CurrentSubStreetNumber OR		-- V1.2
		--ISNULL(@SubStreet,'') <>  @CurrentSubStreet OR				-- V1.2
		ISNULL(@StreetNumber,'') <> @CurrentStreetNumber OR   
		ISNULL(@Street, '') <> @CurrentStreet OR
		ISNULL(@SubLocality,'') <> @CurrentSubLocality OR 
		ISNULL(@Locality,'') <> @CurrentLocality OR
		ISNULL(@Town,'') <> @CurrentTown  OR
		ISNULL(@Region,'') <> @CurrentRegion OR
		ISNULL(@PostCode, '') <> @CurrentPostCode OR
		ISNULL(@CountryID, '') <> @CurrentCountryID




				
		--CHECK IF ADDRESS IS ALREADY ASSOCIATED TO THE PARTY
		IF NOT EXISTS ( SELECT *
						FROM [Meta].[PartyBestPostalAddresses] PBPA 
						INNER JOIN [ContactMechanism].[PartyContactMechanisms] PCM ON PBPA.[ContactMechanismID] = PCM.[ContactMechanismID] AND PBPA.PartyID = PCM.PARTYID
						INNER JOIN [ContactMechanism].[PostalAddresses] PA ON PCM.[ContactMechanismID] = PA.[ContactMechanismID]  AND PA.AddressChecksum = @chkSum 
						WHERE PCM.PartyID = @PartyID
						)	
			
		
		BEGIN

			BEGIN TRAN
	
			DECLARE @AuditItemID dbo.AuditItemID
			DECLARE @ActionDate DATETIME2
			DECLARE @UserPartyID dbo.PartyID
			DECLARE @UserRoleTypeID dbo.RoleTypeID
			DECLARE @ContactMechanismID dbo.ContactMechanismID = 0
		
			SET @ActionDate = GETDATE()
		

			IF ( @SessionID IS NULL ) SELECT @SessionID = 'NEW OWAP Update postal address'
			
			-- get basic OWAPAdmin user details of manually setting data updates
			--
			IF ( @UserPartyRoleID IS NULL)
			BEGIN
					SELECT @UserPartyRoleID = pr.PartyRoleID 
					FROM OWAP.Users U
					INNER JOIN Party.PartyRoles pr ON pr.PartyID = u.PartyID AND pr.RoleTypeID = 51 -- OWAP
					WHERE U.UserName = 'OWAPAdmin'	
			END	
			--
			-- GET THE USER DETAILS
			--
			SELECT
				@UserPartyID = PR.PartyID,
				@UserRoleTypeID = PR.RoleTypeID
			FROM Party.PartyRoles PR
			INNER JOIN OWAP.Users U ON U.PartyID = PR.PartyID AND U.RoleTypeID = PR.RoleTypeID
			WHERE PR.PartyRoleID = @UserPartyRoleID
		
			-- AUDIT THE ACTION AND GET THE RESULTANT AuditItemID
			EXEC [OWAP].[uspAuditSession] @SessionID, @userPartyRoleID, @AuditID Output, @ErrorCode Output
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
				,ISNULL(@CurrentSubStreetNumber, '') AS SubStreetNumber		-- V1.2
				,ISNULL(@CurrentSubStreet, '') AS SubStreet					-- V1.2
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
			SET PA.AddressChecksum = [$(ETLDB)].dbo.udfGenerateAddressChecksum(PA.BuildingName, PA.SubStreetNumber, PA.SubStreet, PA.StreetNumber, PA.Street, PA.SubLocality, PA.Locality, PA.Town, PA.Region, PA.PostCode, PA.CountryID)
			FROM	[$(AuditDB)].Audit.PostalAddresses APA,
					ContactMechanism.PostalAddresses PA
			WHERE APA.AuditItemID = @AuditItemID
			AND PA.ContactMechanismID = @ContactMechanismID
			AND APA.ContactMechanismID = PA.ContactMechanismID


			--FORCE THE UPDATED ADDRESS TO BE INSTANTLY AVAIILABLE IN [Meta].[PartyBestPostalAddresses]
			UPDATE	[Meta].[PartyBestPostalAddresses]
			SET		[ContactMechanismID] = @ContactMechanismID
			WHERE	PartyID = @PartyID


			------------------------------------------------------------------------------------------
			-- V1.1 UPDATE JAPAN CASE CONTACT MECHANISM AND CASE DETAILS WITH LATEST ADDRESS
			------------------------------------------------------------------------------------------
			IF (@CurrentCountryID = (SELECT C.CountryID FROM ContactMechanism.Countries C WHERE C.Country = 'Japan'))
				
				BEGIN
	
					-----------------------------------------------------------------------------------------
					-- UPDATE ContactMechanismID TO REFERENCE UPDATED ADDRESS
					-----------------------------------------------------------------------------------------
					;WITH	NewAddress ( ContactMechanismID, PartyID, CaseID ) AS
					(
						SELECT @ContactMechanismID AS ContactMechanismID ,		-- V1.3
								PCM.PartyID ,
								MAX(CD.CaseID) AS CaseID
						FROM     ContactMechanism.PostalAddresses PA
						INNER JOIN ContactMechanism.ContactMechanisms CM ON PA.ContactMechanismID = CM.ContactMechanismID
																		AND ContactMechanismTypeID = 1
						INNER JOIN ContactMechanism.PartyContactMechanisms PCM ON CM.ContactMechanismID = PCM.ContactMechanismID
						INNER JOIN Meta.CaseDetails CD ON PCM.PartyID = CD.PartyID
						WHERE PCM.PartyID = @PartyID
						GROUP BY PCM.PartyID
					 )
					UPDATE  CCM
					SET     CCM.ContactMechanismID = NA.ContactMechanismID
					FROM    Event.CaseContactMechanisms CCM
					INNER JOIN NewAddress NA ON CCM.CaseID = NA.CaseID
											   AND CCM.ContactMechanismTypeID = 1
					------------------------------------------------------------------------------------------
					
						
					-----------------------------------------------------------------------------------------
					-- UPDATE Sample.Meta.CaseDetails TO REFERENCE UPDATED ADDRESS
					-----------------------------------------------------------------------------------------
					;WITH    NewAddress ( ContactMechanismID, PartyID, CaseID ) AS 
					(
						SELECT @ContactMechanismID AS ContactMechanismID ,		-- V1.3
								PCM.PartyID ,
								MAX(CD.CaseID) AS CaseID
						FROM     ContactMechanism.PostalAddresses PA
						INNER JOIN ContactMechanism.ContactMechanisms CM ON PA.ContactMechanismID = CM.ContactMechanismID
																		AND ContactMechanismTypeID = 1
						INNER JOIN ContactMechanism.PartyContactMechanisms PCM ON CM.ContactMechanismID = PCM.ContactMechanismID
						INNER JOIN Meta.CaseDetails CD ON PCM.PartyID = CD.PartyID
						WHERE PCM.PartyID = @PartyID
						GROUP BY PCM.PartyID
					)
					UPDATE  CD
					SET     CD.PostalAddressContactMechanismID = NA.ContactMechanismID
					FROM    Sample.Meta.CaseDetails CD
					INNER JOIN NewAddress NA ON CD.CaseID = NA.CaseID			
					------------------------------------------------------------------------------------------
	
				END			
				------------------------------------------------------------------------------------------

			
			COMMIT TRAN
		END 

		IF @ErrorCode IS NULL 
			SELECT @ErrorCode = 0 

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
