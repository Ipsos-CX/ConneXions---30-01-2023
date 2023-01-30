CREATE PROCEDURE [DealerManagement].[uspDEALERS_JLRCSP_UPDATE_OutletTown]

AS
SET NOCOUNT ON
SET QUOTED_IDENTIFIER ON

	-- Purpose: Update outlet town details in the sample model (i.e. PostalAddress table)
	--
	--
	-- Version		Developer			Date			Comment
	-- 1.0			Martin Riverol		14/05/2012		Created
	-- 1.1			Martin Riverol		13/07/2012		Once updated, rebuild the flattened table of dealers 
	-- 1.2			Chris Ledger		10/01/2020		BUG 15372 - Fix Hard coded references to databases
	
	-- DECLARE LOCAL VARIABLES 

		DECLARE @ErrorCode INT
		DECLARE @ErrorNumber INT
		DECLARE @ErrorSeverity INT
		DECLARE @ErrorState INT
		DECLARE @ErrorLocation NVARCHAR(500)
		DECLARE @ErrorLine INT
		DECLARE @ErrorMessage NVARCHAR(2048)


		BEGIN TRY

		-- POPULATE WORKSPACE TABLE TO HOLD AUDIT TRAIL INFO

			CREATE TABLE #AuditTrail
				(
					ID INT
					, IP_TownChangeID INT
					, ID_Hierarchy INT
					, PartyID INT
					, RoleTypeID INT
					, PartyRoleID INT
					, AuditID INT
					, AuditItemID INT
				)


			INSERT INTO #AuditTrail
			
				(
					ID
					, IP_TownChangeID
					, ID_Hierarchy
					, PartyID
					, RoleTypeID
					, PartyRoleID
					, AuditID
					, AuditItemID
				)

					SELECT 
						ROW_NUMBER() OVER (ORDER BY UT.IP_TownChangeID) ID
						, UT.IP_TownChangeID
						, UT.ID
						, DU.PartyID
						, DU.RoleTypeID
						, DU.PartyRoleID
						, NULL AS AuditID
						, NULL AS AuditItemID
					FROM DealerManagement.DEALERS_JLRCSP_UPDATE_Town UT
					INNER JOIN [$(SampleDB)].DealerManagement.vwUsers DU ON UT.IP_SystemUser = DU.UserName
					WHERE UT.IP_ProcessedDate IS NULL
					AND UT.IP_DataValidated = 1

		
		-- GET A DISTINCT LIST OF PARTYROLEIDS FROM WORKSPACE TABLE 

			SELECT DISTINCT
				ROW_NUMBER() OVER (ORDER BY PartyRoleID) ID
				, NEWID() AS GUID
				, PartyRoleID 
			INTO #DistinctUsers
			FROM #AuditTrail AR
			GROUP BY PartyRoleID


		-- CREATE AN AUDITID SESSION FOR EACH PARTY WHO HAS WRITTEN UPDATES

		INSERT INTO [$(AuditDB)].OWAP.vwDA_Sessions

			(
				AuditID
				, UserPartyRoleID
				, SessionID
				, SessionTimeStamp 
			)

			SELECT 
				0 AS AuditID
				, DU.PartyRoleID
				, U.UserName + ' - Dealer Town update - ' + CAST(DU.GUID AS NVARCHAR(100)) AS SessionID
				, GETDATE()
			FROM #DistinctUsers DU
			INNER JOIN [$(SampleDB)].DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID


		-- WRITE BACK THE CREATED AUDITID USING THE UNIQUE GUID/SESSIONID

			UPDATE AT
				SET AuditID = S.AuditID
			FROM #DistinctUsers DU
			INNER JOIN [$(SampleDB)].DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID
			INNER JOIN #AuditTrail AT ON DU.PartyRoleID = AT.PartyRoleID
			INNER JOIN [$(AuditDB)].OWAP.Sessions S ON U.UserName + ' - Dealer Town update - ' + CAST(DU.GUID AS VARCHAR(100))= S.SessionID


		-- NOW CREATE SOME AUDITITEMIDS AS OWAP_ACTIONS

			INSERT INTO [$(AuditDB)].owap.vwDA_Actions
			
				(
					AuditItemID
					, AuditID
					, ActionDate
					, UserPartyID
					, UserRoleTypeID
				)

					SELECT 
						AuditItemID
						, AuditID
						, GETDATE()
						, PartyID
						, RoleTypeID
					FROM #AuditTrail

				
		-- WRITE THE CREATED AUDITITEMIDS BACK TO THE WORKSPACE TABLE

			UPDATE A
			SET AuditItemID = A.ID + B.difference
			FROM #AuditTrail A
			INNER JOIN
				(
					SELECT 
						T.AuditID
						, MIN(A.AuditItemID) - MIN(T.ID) AS difference
					FROM #AuditTrail T 
					INNER JOIN [$(AuditDB)].OWAP.Sessions S ON T.AuditID = S.AuditID
					INNER JOIN [$(AuditDB)].dbo.AuditItems I ON S.AuditID = I.AuditID
					INNER JOIN [$(AuditDB)].OWAP.Actions A ON I.AuditItemID = A.AuditItemID
					GROUP BY T.AuditID
				) B
			ON A.AuditID = B.AuditID


		-- WRITE AUDITITEMIDS BACK TO DEALER APPOINTMENT TABLE

			UPDATE UT
				SET IP_AuditItemID = AT.AuditItemID
			FROM #AuditTrail AT
			INNER JOIN DealerManagement.DEALERS_JLRCSP_UPDATE_Town UT ON AT.IP_TownChangeID = UT.IP_TownChangeID

		-- REMOVE CURRENT POSTAL ADDRESS FOR THIS DEALER
		
			DELETE FROM PCM
			FROM DealerManagement.DEALERS_JLRCSP_UPDATE_Town UT
			INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON UT.IP_OutletPartyID = PCM.PartyID
			WHERE UT.IP_ProcessedDate IS NULL
			AND UT.IP_DataValidated = 1

		-- ADD NEW POSTAL ADDRESS

			INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_PostalAddresses
				
				(
					AuditItemID
					, AddressParentAuditItemID
					, ContactMechanismID
					, ContactMechanismTypeID
					, BuildingName
					, SubStreetNumber
					, SubStreet
					, StreetNumber
					, Street
					, SubLocality
					, Locality
					, Town
					, Region
					, CountryID
					, AddressChecksum
				)
				
					SELECT
						UT.IP_AuditItemID
						, UT.IP_AuditItemID AS IP_AddressParentAuditItemID
						, 0 AS ContactMechanismID 
						, 1 AS ContactMechanismTypeID --Postal address
						, N'' AS BuildingName
						, N'' AS SubStreetNumber
						, N'' AS SubStreet
						, N'' AS StreetNumber
						, N'' AS Street
						, N'' AS SubLocality
						, N'' AS Locality
						, UT.NewTown AS Town
						, N'' AS Region
						, DC.CountryID AS CountryID
						, 0 AS AddressChecksum
					FROM DealerManagement.DEALERS_JLRCSP_UPDATE_Town AS UT
					INNER JOIN 
						(
							SELECT DISTINCT
								D.OutletPartyID
								, D.Market
								, C.CountryID
							FROM [$(SampleDB)].dbo.DW_JLRCSPDealers D
							LEFT JOIN
								(
									SELECT
										CountryID,
										CASE COALESCE(Countryshortname, Country)
											WHEN 'Belgium' THEN 'Belux'
											WHEN 'United Kingdom' THEN 'UK'
											ELSE COALESCE(Countryshortname, country)
										END Market
									FROM [$(SampleDB)].ContactMechanism.Countries					
								) C
							ON D.Market = C.Market
						) DC
					ON UT.IP_OutletPartyID = DC.OutletPartyID
					WHERE UT.IP_ProcessedDate IS NULL
					AND UT.IP_DataValidated = 1

		-- WRITE CONTACTMECHANISM BACK TO DEALER TOWN UPDATE TABLE

				UPDATE UT
					SET IP_ContactMechanismID = APA.ContactMechanismID
				FROM DealerManagement.DEALERS_JLRCSP_UPDATE_Town UT
				INNER JOIN [$(AuditDB)].Audit.PostalAddresses APA ON UT.IP_AuditItemID = APA.AuditItemID
				WHERE UT.IP_ProcessedDate IS NULL
				AND UT.IP_DataValidated = 1


		-- WRITE PARTYPOSTALADDDRESSES (I.E. TIE NEW DEALERS TO THEIR ADDRESSES)

			INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_PartyPostalAddresses

				(
					AuditItemID, 
					ContactMechanismID, 
					PartyID, 
					FromDate, 
					ContactMechanismPurposeTypeID
				)
					SELECT
						UT.IP_AuditItemID
						, UT.IP_ContactMechanismID 
						, UT.IP_OutletPartyID 
						, GETDATE() AS FromDate 
						, 2 AS ContactMechanismPurposeTypeID --Main business address
					FROM DealerManagement.DEALERS_JLRCSP_UPDATE_Town UT
					WHERE UT.IP_ProcessedDate IS NULL
					AND UT.IP_DataValidated = 1
					AND UT.IP_ContactMechanismID IS NOT NULL 
					AND UT.IP_OutletPartyID IS NOT NULL


	-- STAMP THE RECORDS AS PROCESSES
		
		UPDATE UT
			SET IP_ProcessedDate = GETDATE()
		FROM #AuditTrail AT
		INNER JOIN DealerManagement.DEALERS_JLRCSP_UPDATE_Town UT ON AT.AuditItemID = UT.IP_AuditItemID
		WHERE IP_DataValidated = 1

	-- REBUILD FLATTENED DEALER TABLE 
	
		EXEC DealerManagement.uspDEALERS_JLRCSP_CreateFlatDealerList
				
	END TRY

	BEGIN CATCH

		SET @ErrorCode = @@Error

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