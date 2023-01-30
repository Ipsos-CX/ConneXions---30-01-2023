CREATE PROCEDURE [DealerManagement].[uspDEALERS_JLRCSP_DoAppointments]

AS

SET NOCOUNT ON

	-- 1.1			Martin Riverol		13/07/2012		Once added, rebuild the flattened table of dealers 
	-- 1.2			Martin Riverol		11/04/2013		Write the GDD outlet code to the dealernetworks table and dw_jlrcspdealers table
	-- 1.3			Ali yuksel			13/01/2014		Bug 9733 - Inserting records into CONTACTMECHANISM.DEALERCOUNTRIES has been changed 
	-- 1.4			Chris Ross			25/02/2015		BUG 11026 - Add in Business Region to update mechanism
	-- 1.5			Chris Ross			27/01/2016		BUG 12038 - Update #functions table to include new types 'Pre-Owned' and 'All'.
	-- 1.6			Chris Ross			12/10/2016		BUG 13171 - Added in new SubNationalTerritory column
	-- 1.7			Chris Ledger		24/02/2017		BUG 13621 - Add in code to check for existing Dealer PartyID and use it when adding new dealers with different functions.	
	-- 1.8			Chris Ledger		11/04/2017		BUG 13621 - Dealer name can be different when checking for existing Dealer PartyID
	-- 1.9			Chris Ledger		13/03/2017		BUG 13621 - Fix bug where DealerCountries row not added when new function added for existing DealerPartyID
	-- 1.10			Chris Ledger		03/06/2017		BUG 13993 - UPDATE @ImporterPartyID BASED ON vwBrandMarketQuestionnaireSampleMetadata VALUE 
	-- 1.11			Chris Ledger		09/08/2017		BUG 13992 - Add Bodyshop	RELEASED LIVE: CL 2017-08-31	
	-- 1.12			Chris Ledger		31/09/2017		BUG 14209 - Change Check for Existing DealerPartyID to include BOTH OutletFunction	RELEASED LIVE: CL 2017-08-31	
	-- 1.13			Chris Ledger		13/11/2017		BUG 14365 - Add SVODealer & FleetDealer	
	-- 1.14			Chris Ledger		10/01/2020		BUG 15372 - Fix Hard coded references to databases
	-- 1.15			Chris Ledger		06/02/2020		BUG 15793 - Add Dealer10DigitCode
	
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
				ID int
				, IP_DealerAppointmentID int
				, PartyID int
				, RoleTypeID int
				, PartyRoleID int
				, AuditID int
				, AuditItemID int
			)

		INSERT INTO #AuditTrail
		
			(
				ID
				, IP_DealerAppointmentID
				, PartyID
				, RoleTypeID
				, PartyRoleID
				, AuditID
				, AuditItemID
			)

				SELECT 
					ROW_NUMBER() OVER (ORDER BY IP_DealerAppointmentID) ID
					, DA.IP_DealerAppointmentID
					, DU.PartyID
					, DU.RoleTypeID
					, DU.PartyRoleID
					, NULL AS AuditID
					, NULL AS AuditItemID
				FROM DealerManagement.DEALERS_JLRCSP_Appointments DA
				INNER JOIN [$(SampleDB)].DealerManagement.vwUsers DU ON DA.IP_SystemUser = DU.UserName
				WHERE DA.IP_ProcessedDate IS NULL
				AND DA.IP_DataValidated = 1

		
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
				, U.UserName + ' - Dealer Insert - ' + CAST(DU.GUID AS NVARCHAR(100)) AS SessionID
				, GETDATE()
			FROM #DistinctUsers DU
			INNER JOIN [$(SampleDB)].DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID


		-- WRITE BACK THE CREATED AUDITID USING THE UNIQUE GUID/SESSIONID

			UPDATE AT
				SET AuditID = S.AuditID
			FROM #DistinctUsers DU
			INNER JOIN [$(SampleDB)].DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID
			INNER JOIN #AuditTrail AT ON DU.PartyRoleID = AT.PartyRoleID
			INNER JOIN [$(AuditDB)].OWAP.Sessions S ON U.UserName + ' - Dealer Insert - ' + CAST(DU.GUID AS VARCHAR(100))= S.SessionID


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
		
			UPDATE DA
				SET IP_AuditItemID = AT.AuditItemID
			FROM #AuditTrail AT
			INNER JOIN DealerManagement.DEALERS_JLRCSP_Appointments DA ON AT.IP_DealerAppointmentID = DA.IP_DealerAppointmentID


		-- ASSIGN PARENT ORGANISATION AUDITITEMID IN DEALER APPOINTMENT TABLE
		
			UPDATE DA
				SET IP_OrganisationParentAuditItemID = OPAD.IP_OrganisationParentAuditItemID
			FROM DealerManagement.DEALERS_JLRCSP_Appointments DA
			INNER JOIN
				(
					SELECT 
						OutletCode
						--, OutletName	-- 1.8
						, Market
						, Manufacturer
						, MIN(IP_AuditItemID) AS IP_OrganisationParentAuditItemID
					FROM DealerManagement.DEALERS_JLRCSP_Appointments 
					WHERE IP_ProcessedDate IS NULL
					AND IP_DataValidated = 1
					GROUP BY
						OutletCode
						--, OutletName 	-- 1.8
						, Market
						, Manufacturer
				) OPAD
			ON DA.OutletCode = OPAD.OutletCode
			--AND DA.OutletName = OPAD.OutletName	-- 1.8
			AND DA.Market = OPAD.Market
			AND DA.Manufacturer = OPAD.Manufacturer
			AND DA.IP_ProcessedDate IS NULL
			AND DA.IP_DataValidated = 1	


			------------------------------------------------------------------------------------------------------------------------------
			-- V1.3 UPDATE IP_OutletPartyID AND ContactMechanismID TO EXISTING PartyID IF DEALER ALREADY EXISTS
			-- USE EXISTING PARTYID OF LOWEST OutletFunctionID (I.E. SALES THEN SERVICE THEN PREOWNED) 
			-- ASSIGNS IP_OutletPartyID SO NEW ORGANISATIONS AREN'T ADDED
			-- AND ContactMechanismID SO NEW POSTAL ADDRESS 
			------------------------------------------------------------------------------------------------------------------------------		
			--SELECT D.OutletPartyID, DA.ContactMechanismID, DAN.*
			UPDATE DAN SET DAN.IP_OutletPartyID = D.OutletPartyID, DAN.ContactMechanismID = DA.ContactMechanismID
			FROM [$(SampleDB)].dbo.DW_JLRCSPDealers D
			INNER JOIN 
				(SELECT MIN(D.OutletFunctionID) AS OutletFunctionID,
				DA.Manufacturer,
				DA.Market,
				DA.OutletCode
				--,DA.OutletName	-- 1.8
				FROM DealerManagement.DEALERS_JLRCSP_Appointments DA
				INNER JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON DA.IP_OutletPartyID = D.OutletPartyID				
					AND (DA.Functions = D.OutletFunction OR (DA.Functions = 'Both' AND (D.OutletFunction = 'Sales' OR D.OutletFunction = 'Aftersales'))) -- V1.11
				WHERE DA.IP_DataValidated = 1
				AND DA.IP_ProcessedDate IS NOT NULL
				AND D.ThroughDate IS NULL								--V1.3 ONLY GET ACTIVE DEALERS
				GROUP BY DA.Manufacturer,
				DA.Market,
				DA.OutletCode
				--,DA.OutletName	-- 1.8
				) ED 
				ON D.Manufacturer = ED.Manufacturer
					AND D.Market = ED.Market
					AND D.OutletCode = ED.OutletCode
					--AND D.Outlet = ED.OutletName	-- 1.8
					AND D.OutletFunctionID = ED.OutletFunctionID
			INNER JOIN DealerManagement.DEALERS_JLRCSP_Appointments DA ON D.OutletPartyID = DA.IP_OutletPartyID				
					AND (D.OutletFunction = DA.Functions OR ((D.OutletFunction = 'Sales' OR D.OutletFunction = 'Aftersales') AND DA.Functions = 'Both')) -- V1.11
			INNER JOIN DealerManagement.DEALERS_JLRCSP_Appointments DAN ON DA.Manufacturer = DAN.Manufacturer
										AND DA.Market = DAN.Market
										AND DA.OutletCode = DAN.OutletCode
										--AND DA.OutletName = DAN.OutletName	-- 1.8
			WHERE DAN.IP_DataValidated = 1
			AND DAN.IP_ProcessedDate IS NULL
			------------------------------------------------------------------------------------------------------------------------------
			
		
		-- WRITE ORGANISATIONS (I.E. DEALERS) INTO SAMPLE MODEL
		
			INSERT INTO [$(SampleDB)].Party.vwDA_LegalOrganisations
				
				(
					 AuditItemID
					, ParentAuditItemID
					, PartyID
					, FromDate
					, OrganisationName
					, LegalName	
				)

					SELECT 
						IP_AuditItemID AS AuditItemID
						, IP_OrganisationParentAuditItemID AS ParentAuditItemID
						, ISNULL(IP_OutletPartyID, 0) AS PartyID
						, FromDate
						, OutletName AS OrganisationName
						, OutletName AS LegalName
					FROM DealerManagement.DEALERS_JLRCSP_Appointments
					WHERE IP_DataValidated = 1
					AND IP_OutletPartyID IS NULL
					AND IP_ProcessedDate IS NULL

				
		-- WRITE NEWLY CREATED DEALERS PARTYID BACK TO APPOINTMENT TABLE
		
			UPDATE DA
				SET IP_OutletPartyID = AO.PartyID
			FROM DealerManagement.DEALERS_JLRCSP_Appointments DA
			INNER JOIN [$(AuditDB)].Audit.Organisations AO ON DA.IP_AuditItemID = AO.AuditItemID
			WHERE IP_ProcessedDate IS NULL AND IP_DataValidated = 1
		
		-- ORGANISATION PARTIES NOW CREATED SO LETS NOW LOAD THESE PARTIES AS DEALERS

		-- CREATE TABLE TO RESOLVE THE TEXTUAL ENTRIES IN THE 'FUNCTIONS' COLUMN INTO IDS		
		-- v1.5 - Modified to include PreOwned and a RoleTypeFuntionName column for reference further on
		SELECT RoleTypeID, 
				CASE WHEN RoleType = 'Authorised Dealer (Sales)'		THEN 'Sales' 
					 WHEN RoleType = 'Authorised Dealer (Aftersales)'	THEN 'Aftersales'
					 WHEN RoleType = 'Authorised Dealer (PreOwned)'		THEN 'PreOwned'  
					 WHEN RoleType = 'Authorised Dealer (Bodyshop)'		THEN 'Bodyshop'		-- V1.11 
				END AS RoleTypeFuntionName,
				CASE WHEN RoleType = 'Authorised Dealer (Sales)'		THEN 'Sales' 
					 WHEN RoleType = 'Authorised Dealer (Aftersales)'	THEN 'Aftersales'
					 WHEN RoleType = 'Authorised Dealer (PreOwned)'		THEN 'PreOwned'  
					 WHEN RoleType = 'Authorised Dealer (Bodyshop)'		THEN 'Bodyshop'		-- V1.11
				END AS Functions
		INTO #Functions
		FROM [$(SampleDB)].dbo.RoleTypes
		WHERE RoleType IN (
							'Authorised Dealer (Sales)',
							'Authorised Dealer (Aftersales)',
							'Authorised Dealer (PreOwned)',
							'Authorised Dealer (Bodyshop)'		-- V1.11
						)
		UNION
		SELECT RoleTypeID, 
				CASE WHEN RoleType = 'Authorised Dealer (Sales)'		THEN 'Sales' 
					 WHEN RoleType = 'Authorised Dealer (Aftersales)'	THEN 'Aftersales'
					 WHEN RoleType = 'Authorised Dealer (PreOwned)'		THEN 'PreOwned'  
					 WHEN RoleType = 'Authorised Dealer (Bodyshop)'		THEN 'Bodyshop'  
				END AS RoleTypeFuntionName,
				'All' Functions
		FROM [$(SampleDB)].dbo.RoleTypes
		WHERE RoleType IN (
							'Authorised Dealer (Sales)',
							'Authorised Dealer (Aftersales)',
							'Authorised Dealer (PreOwned)',
							'Authorised Dealer (Bodyshop)'
						)
		UNION
		SELECT RoleTypeID, 
				CASE WHEN RoleType = 'Authorised Dealer (Sales)'		THEN 'Sales' 
					 WHEN RoleType = 'Authorised Dealer (Aftersales)'	THEN 'Aftersales'
				END AS RoleTypeFuntionName,
				'Both' Functions
		FROM [$(SampleDB)].dbo.RoleTypes
		WHERE RoleType IN (
							'Authorised Dealer (Sales)',
							'Authorised Dealer (Aftersales)'
						)


		-- V1.10 UPDATE @ImporterPartyID BASED ON vwBrandMarketQuestionnaireSampleMetadata VALUE
			UPDATE D SET D.ImporterPartyID = SM.DealerCodeOriginatorPartyID 
			FROM DealerManagement.DEALERS_JLRCSP_Appointments D
				INNER JOIN #Functions AS F ON D.Functions = F.Functions
				LEFT JOIN [$(SampleDB)].dbo.Markets M ON D.Market = ISNULL(M.DealerTableEquivMarket,M.Market)
				LEFT JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata SM ON M.Market = SM.Market
																			AND D.Manufacturer = SM.Brand
																			AND F.Functions = SM.Questionnaire
			WHERE D.IP_ProcessedDate IS NULL
			AND D.IP_DataValidated = 1
			AND ISNULL(SM.DealerCodeOriginatorPartyID, 0) > 0
			AND ISNULL(SM.DealerCodeOriginatorPartyID, 0) NOT IN (2,3)


		-- INSERT DEALER NETWORKS RELATIONSHIPS - USE THE LOCAL LANGAUGE NAME FOR THE DELAER NAME COLUMN

			INSERT INTO [$(SampleDB)].Party.vwDA_DealerNetworks

				(
					AuditItemID 
					, PartyIDFrom 
					, PartyIDTo 
					, RoleTypeIDFrom 
					, RoleTypeIDTo 
					, DealerCode 
					, DealerShortName 
					, FromDate 
				)


		-- LOAD DEALER IMPORTER RELATIONSHIPS WITH OUTLETS
		
				SELECT
					D.IP_AuditItemID
					, D.IP_OutletPartyID AS PartyIDFrom 
					, D.ImporterPartyID AS PartyIDTo 
					, F.RoleTypeID AS RoleTypeIDFrom 
					, 19 AS RoleTypeIDTo 
					, ISNULL(D.OutletCode_Importer, '') AS DealerCode 
					, COALESCE(NULLIF(D.OutletName_NativeLanguage, ''), D.OutletName_Short) AS DealerShortName 
					, D.FromDate
				FROM DealerManagement.DEALERS_JLRCSP_Appointments D
				INNER JOIN #Functions AS F ON D.Functions = F.Functions
				WHERE D.IP_ProcessedDate IS NULL
				AND D.IP_DataValidated = 1
				AND NULLIF(D.ImporterPartyID, 0) > 0
			UNION
		-- LOAD VEHICLE MANUFACTURER RELATIONSHIPS WITH OUTLETS (STANDARD CODES)
				SELECT
					D.IP_AuditItemID 
					, D.IP_OutletPartyID AS PartyIDFrom 
					, D.ManufacturerPartyID AS PartyIDTo 
					, F.RoleTypeID AS RoleTypeIDFrom 
					, 7 AS RoleTypeIDTo 
					, ISNULL(D.OutletCode_Manufacturer, '') AS DealerCode 
					, COALESCE(NULLIF(D.OutletName_NativeLanguage, ''), D.OutletName_Short) AS DealerShortName 
					, D.FromDate
				FROM DealerManagement.DEALERS_JLRCSP_Appointments AS D
				INNER JOIN #Functions AS F ON D.Functions = F.Functions
				WHERE D.IP_ProcessedDate IS NULL
				AND D.IP_DataValidated = 1
				AND D.ManufacturerPartyID IS NOT NULL
			UNION
		-- LOAD VEHICLE MANUFACTURER RELATIONSHIPS WITH OUTLETS (WARRANTY CODES)
				SELECT
					D.IP_AuditItemID
					, D.IP_OutletPartyID AS PartyIDFrom 
					, D.ManufacturerPartyID AS PartyIDTo 
					, F.RoleTypeID AS RoleTypeIDFrom 
					, 7 AS RoleTypeIDTo 
					, ISNULL(D.OutletCode_Warranty, '') AS DealerCode 
					, COALESCE(NULLIF(D.OutletName_NativeLanguage, ''), D.OutletName_Short) AS DealerShortName 
					, D.FromDate
				FROM DealerManagement.DEALERS_JLRCSP_Appointments AS D
				INNER JOIN #Functions AS F ON D.Functions = F.Functions
				WHERE D.IP_ProcessedDate IS NULL
				AND D.IP_DataValidated = 1
				AND D.ManufacturerPartyID IS NOT NULL
			UNION
		-- LOAD VEHICLE MANUFACTURER RELATIONSHIPS WITH OUTLETS (WARRANTY CODES)
				SELECT
					D.IP_AuditItemID
					, D.IP_OutletPartyID AS PartyIDFrom 
					, D.ManufacturerPartyID AS PartyIDTo 
					, F.RoleTypeID AS RoleTypeIDFrom 
					, 7 AS RoleTypeIDTo 
					, ISNULL(D.OutletCode_GDD, '') AS DealerCode 
					, COALESCE(NULLIF(D.OutletName_NativeLanguage, ''), D.OutletName_Short) AS DealerShortName 
					, D.FromDate
				FROM DealerManagement.DEALERS_JLRCSP_Appointments AS D
				INNER JOIN #Functions AS F ON D.Functions = F.Functions
				WHERE D.IP_ProcessedDate IS NULL
				AND D.IP_DataValidated = 1
				AND D.ManufacturerPartyID IS NOT NULL
			
		-- ASSIGN PARENT POSTAL ADDRESS AUDITITEMID IN DEALER APPOINTMENT TABLE
			
			UPDATE D
				SET D.IP_AddressParentAuditItemID = P.AddressParentAuditItemID
			FROM DealerManagement.DEALERS_JLRCSP_Appointments AS D
			INNER JOIN 

				(
					SELECT
						COALESCE(D.BuildingName , '') AS BuildingName
						, COALESCE(D.SubStreetNumber , '') AS SubStreetNumber 
						, COALESCE(D.SubStreet , '') AS SubStreet 
						, COALESCE(D.StreetNumber , '') AS StreetNumber 
						, COALESCE(D.Street , '') AS Street 
						, COALESCE(D.SubLocality , '') AS SubLocality 
						, COALESCE(D.Locality , '') AS Locality 
						, COALESCE(D.Town , '') AS Town 
						, COALESCE(D.Region , '') AS Region 
						, COALESCE(D.PostCode , '') AS PostCode 
						, CountryID 
						, MIN(D.IP_AuditItemID) AS AddressParentAuditItemID
					FROM DealerManagement.DEALERS_JLRCSP_Appointments AS D
					WHERE D.IP_ProcessedDate IS NULL
					AND D.IP_DataValidated = 1
					AND D.ContactMechanismID IS NULL
					GROUP BY
						COALESCE(D.BuildingName , ''), 
						COALESCE(D.SubStreetNumber , ''), 
						COALESCE(D.SubStreet , ''), 
						COALESCE(D.StreetNumber , ''), 
						COALESCE(D.Street , ''), 
						COALESCE(D.SubLocality , ''), 
						COALESCE(D.Locality , ''), 
						COALESCE(D.Town , ''), 
						COALESCE(D.Region , ''), 
						COALESCE(D.PostCode , ''),
						D.CountryID
				) AS P 
			ON P.BuildingName = COALESCE(D.BuildingName , '')
			AND P.SubStreetNumber = COALESCE(d.SubStreetNumber , '')
			AND P.SubStreet = COALESCE(d.SubStreet , '')
			AND P.StreetNumber = COALESCE(D.StreetNumber , '')
			AND P.Street = COALESCE(D.Street , '')
			AND P.SubLocality = COALESCE(D.SubLocality , '')
			AND P.Locality = COALESCE(D.Locality , '')
			AND P.Town = COALESCE(D.Town , '')
			AND P.Region = COALESCE(D.Region , '')
			AND P.PostCode = COALESCE(D.PostCode , '')
			AND P.CountryID = D.CountryID
			WHERE 
				D.IP_ProcessedDate IS NULL
				AND D.IP_DataValidated = 1
				AND D.ContactMechanismID IS NULL

		
		-- NOW ADD ADDRESSES

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
						D.IP_AuditItemID
						, D.IP_AddressParentAuditItemID
						, 0 AS ContactMechanismID 
						, 1 AS ContactMechanismTypeID --Postal address
						, D.BuildingName
						, D.SubStreetNumber
						, D.SubStreet
						, D.StreetNumber
						, D.Street
						, D.SubLocality
						, D.Locality
						, D.Town
						, D.Region
						, D.CountryID
						, 0 AS AddressChecksum
					FROM DealerManagement.DEALERS_JLRCSP_Appointments AS D
					WHERE D.IP_ProcessedDate IS NULL
					AND D.IP_DataValidated = 1
					AND NULLIF(D.ContactMechanismID, 0) IS NULL
					AND ISNULL(D.CountryID, 0) > 0
		
		

		-- WRITE CONTACTMECHANISM BACK TO DEALER APPOINTMENT TABLE

				UPDATE D
					SET ContactMechanismID = APA.ContactMechanismID
				FROM DealerManagement.DEALERS_JLRCSP_Appointments D
				INNER JOIN [$(AuditDB)].Audit.PostalAddresses APA ON D.IP_AuditItemID = APA.AuditItemID
				WHERE D.IP_ProcessedDate IS NULL
				AND D.IP_DataValidated = 1
				AND NULLIF(D.ContactMechanismID, 0) IS NULL
				AND ISNULL(D.CountryID, 0) > 0
			

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
						D.IP_AuditItemID
						, D.ContactMechanismID 
						, D.IP_OutletPartyID 
						, D.FromDate, 
						2 AS ContactMechanismPurposeTypeID --Main business address
					FROM DealerManagement.DEALERS_JLRCSP_Appointments AS D
					WHERE D.IP_ProcessedDate IS NULL
					AND D.IP_DataValidated = 1
					AND D.ContactMechanismID IS NOT NULL 
					AND D.IP_OutletPartyID IS NOT NULL
					AND D.IP_AddressParentAuditItemID IS NOT NULL	-- V1.7 ONLY ADD IF NEW CONTACT MECHANISM
		
		-- 	ADD PARTY LANGUAGE IF ONE HAS BEEN SUPPLIED

			INSERT INTO [$(SampleDB)].Party.vwDA_PartyLanguages

				(
					AuditItemID 
					, PartyID 
					, LanguageID 
					, FromDate 
					, PreferredFlag
				)

					SELECT
						D.IP_AuditItemID
						, D.IP_OutletPartyID
						, D.LanguageID
						, D.FromDate, 
						1 AS PreferredFlag
					FROM DealerManagement.DEALERS_JLRCSP_Appointments AS D
					WHERE D.IP_ProcessedDate IS NULL
					AND D.IP_DataValidated = 1
					AND ISNULL(D.LanguageID, 0) > 0

					
		-- UPDATE DEALER DIMENSION TABLE WITH INITIAL HIERARCHY ENTRIES. N.B. WHEN A DEALER IS CREATED IT WILL TRANSFER TO ITSELF. 

			INSERT INTO [$(SampleDB)].DBO.DW_JLRCSPDealers

				(
					Manufacturer, 
					SupernationalRegion, 
					BusinessRegion,					-- 1.4
					Market, 
					SubNationalTerritory,			-- 1.5 
					SubNationalRegion, 
					CombinedDealer,
					TransferDealer, 
					TransferDealerCode, 
					Outlet, 
					OutletCode, 
					OutletFunction, 
					ManufacturerPartyID, 
					MarketPartyID, 
					TransferPartyID, 
					OutletPartyID, 
					OutletLevelReport, 
					OutletLevelWeb, 
					OutletFunctionID, 
					OutletSiteCode, 
					FromDate,
					TransferDealerCode_GDD,
					OutletCode_GDD,
					PAGCode,
					PAGName,
					SVODealer,						-- V1.13
					FleetDealer,					-- V1.13
					Dealer10DigitCode				-- V1.15
				)
				
					SELECT
						D.Manufacturer 		
						, LTRIM(RTRIM(D.SupernationalRegion)) AS SupernationalRegion 
						, LTRIM(RTRIM(D.BusinessRegion)) AS BusinessRegion 
						, LTRIM(RTRIM(D.Market)) AS Market 
						, LTRIM(RTRIM(D.SubnationalTerritory)) AS SubnationalTerritory 
						, LTRIM(RTRIM(D.SubnationalRegion)) AS SubnationalRegion 
						, LTRIM(RTRIM(D.CombinedDealer)) AS CombinedDealer
						, LTRIM(RTRIM(D.OutletName)) AS TransferDealer
						, LTRIM(RTRIM(D.OutletCode)) AS TransferDealerCode 
						, D.OutletName
						, D.OutletCode
						, F.RoleTypeFuntionName AS OutletFunction			-- v1.5
						, D.ManufacturerPartyID 
						, 0 AS MarketPartyID 
						, D.IP_OutletPartyID AS TransferPartyID 
						, D.IP_OutletPartyID 
						, 1 AS OutletLevelReport 
						, 1 AS OutletLevelWeb 
						, F.RoleTypeID
						, D.OutletCode_Warranty
						, D.FromDate
						, D.OutletCode_GDD
						, D.OutletCode_GDD
						, D.PAGCode
						, D.PAGName
						, D.SVODealer										-- V1.13
						, D.FleetDealer										-- V1.13
						, D.Dealer10DigitCode								-- V1.15
					FROM DealerManagement.DEALERS_JLRCSP_Appointments AS D
					INNER JOIN #Functions AS F ON D.Functions = F.Functions
					WHERE D.IP_ProcessedDate IS NULL		
					AND D.IP_DataValidated = 1
					
		--INSERT RECORDS INTO TABLE CONTACTMECHANISM.DEALERCOUNTRIES
			
				INSERT INTO [$(SampleDB)].ContactMechanism.DealerCountries
				SELECT DISTINCT 
						D.IP_OutletPartyID,
						dn.PartyIDTo,
						dn.RoleTypeIDFrom,
						dn.RoleTypeIDTo,
						dn.DealerCode,
						D.CountryID 
				FROM DealerManagement.DEALERS_JLRCSP_Appointments D
				INNER JOIN [$(SampleDB)].Party.DealerNetworks dn on d.IP_OutletPartyID = dn.PartyIDFrom
				WHERE D.IP_ProcessedDate IS NULL
				AND D.IP_DataValidated = 1
				AND NOT EXISTS		-- V1.6 ADD WHERE ROW DOESN'T ALREADY EXIST
				(SELECT * FROM [$(SampleDB)].ContactMechanism.DealerCountries dc
				WHERE dc.PartyIDFrom = dn.PartyIDFrom AND dc.PartyIDTo = dn.PartyIDTo AND dc.RoleTypeIDFrom = dn.RoleTypeIDFrom AND dc.RoleTypeIDTo = dn.RoleTypeIDTo)
				--AND D.IP_AddressParentAuditItemID IS NOT NULL	-- V1.7 ONLY ADD IF NEW CONTACT MECHANISM -- V1.9 ADD FOR ALL CONTACT MECHANISMS				
				

		
		-- STAMP THE RECORDS AS PROCESSES
		
			UPDATE DA
				SET IP_ProcessedDate = GETDATE()
			FROM #AuditTrail AT
			INNER JOIN DealerManagement.DEALERS_JLRCSP_Appointments DA ON AT.AuditItemID = DA.IP_AuditItemID
			WHERE DA.IP_ProcessedDate IS NULL
			AND DA.IP_DataValidated = 1
		
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