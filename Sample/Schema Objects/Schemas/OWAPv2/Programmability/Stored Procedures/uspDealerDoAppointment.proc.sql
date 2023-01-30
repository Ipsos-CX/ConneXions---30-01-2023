CREATE PROCEDURE OWAPv2.uspDealerDoAppointment 
	 @Functions					NVARCHAR(25)
	,@Manufacturer				NVARCHAR(510) 
	,@SuperNationalRegion		NVARCHAR(150) 
	,@BusinessRegion			NVARCHAR(150) 
	,@Market					NVARCHAR(255) 
	,@SubNationalTerritory		NVARCHAR(255)
	,@SubNationalRegion			NVARCHAR(255)
	,@CombinedDealer			NVARCHAR(255) 
	,@OutletName				NVARCHAR(510) 
	,@OutletName_NativeLanguage	NVARCHAR(510) 
	,@OutletName_Short			NVARCHAR(510) 
	,@OutletCode				NVARCHAR(10) 
	,@OutletCode_Manufacturer	NVARCHAR(10) 
	,@OutletCode_Warranty		NVARCHAR(10) 
	,@OutletCode_Importer		NVARCHAR(10)
	,@OutletCode_GDD			NVARCHAR(10) 
	,@PAGCode					NVARCHAR(10) 
	,@PAGName					NVARCHAR(100) 
	,@ImporterPartyID			INT
	,@Town						NVARCHAR(400)	
	,@Region					NVARCHAR(400) 
	,@FromDate					SMALLDATETIME 
	,@LanguageID				SMALLINT 
	,@SVODealer					BIT
	,@FleetDealer				BIT
	,@IP_SystemUser				VARCHAR (50) 
	,@DataValidated				BIT			  OUTPUT
	,@ValidationFailureReasons	VARCHAR(1000) OUTPUT
AS
SET NOCOUNT ON

/*
	Purpose:	Do a dealer appointment 
			
	Version			Date			Developer			Comment
	1.0				14/09/2016		Chris Ross			Original version (adapted from the Sample_ETL Dealer scripts and views)
	1.1				04/10/2016		Chris Ross			13181 - Comment out DealerManagement.uspDEALERS_JLRCSP_CreateFlatDealerList as we will run seperately, as required. 
	1.2				11/10/2016		Chris Ross			13171 - Add in new heirarchy level SubNationalTerritory.  Also do lookups to ensure the params are valid in the Dealer Heirarchy.
	1.3				24/02/2017		Chris Ledger		13621 - Add in code to check for existing Dealer PartyID and use it when adding new dealers with different functions.
	1.4				28/02/2017		Chris Ledger		13642 - Add in fix to set Market to DealerEquivalentMarket as drop-downs use Market
	1.5				11/04/2017		Chris Ledger		13621 - Dealer name can be different when checking for existing DealerPartyID
	1.6				13/04/2017		Chris Ledger		13621 - Fix bug where DealerCountries row not added when new function added for existing DealerPartyID
	1.7				03/06/2017		Chris Ledger		13993 - UPDATE @ImporterPartyID BASED ON vwBrandMarketQuestionnaireSampleMetadata VALUE 
	1.8				09/08/2017		Chris Ledger		13992 - Add Bodyshop	RELEASED LIVE: CL 2017-08-31
	1.9				31/08/2017		Chris Ledger		14209 - Change Check for Existing DealerPartyID to include BOTH OutletFunction	RELEASED LIVE: CL 2017-08-31	
	1.10			28/03/2018		Ben King			14637 - DDB Updates - Subnational territory corrections in hierachy
*/


DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY
	
		-- CREATE A WORKING TABLE
		CREATE TABLE #NewDealers
		
			(
				  [Functions] [nvarchar](25) NOT NULL
				, [Manufacturer] NVARCHAR(510) NULL
				, [SuperNationalRegion] NVARCHAR(150) NULL
				, [BusinessRegion] NVARCHAR(150) NULL				
				, [Market] NVARCHAR(255) NOT NULL
				, [SubNationalRegion] NVARCHAR(255) NULL
				, [SubNationalTerritory] NVARCHAR(255) NULL			--v1.2
				, [CombinedDealer] NVARCHAR(255) NULL
				, [OutletName] NVARCHAR(510) NOT NULL
				, [OutletName_NativeLanguage] NVARCHAR(510) NULL
				, [OutletName_Short] NVARCHAR(510) NOT NULL
				, [OutletCode] NVARCHAR(10) NOT NULL
				, [OutletCode_Manufacturer] NVARCHAR(10) NULL
				, [OutletCode_Warranty] NVARCHAR(10) NULL
				, [OutletCode_Importer] NVARCHAR(10) NULL
				, [OutletCode_GDD] NVARCHAR(10) NULL
				, [PAGCode]	NVARCHAR(10) NULL
				, [PAGName]	NVARCHAR(100) NULL
				, [ImporterPartyID] INT NULL
				, [Town] NVARCHAR(400) NULL
				, [Region] NVARCHAR(400) NULL
				, [FromDate] [smalldatetime] NOT NULL
				, [LanguageID] SMALLINT NULL
				, [IP_SystemUser] [VARCHAR](50) NOT NULL
				, [DataValidated] BIT DEFAULT(1)
				, [ValidationFailureReasons] VARCHAR(1000) DEFAULT('')
			)
		
		-- ADD DATA INSERTED INTO DATA ACCESS VIEW INTO WORKING TABLE
	    INSERT INTO #NewDealers
	    
			(
				Functions
				, Manufacturer
				, SuperNationalRegion
				, BusinessRegion
				, Market
				, SubNationalTerritory					--v1.2
				, SubNationalRegion
				, CombinedDealer
				, OutletName
				, OutletName_NativeLanguage
				, OutletName_Short
				, OutletCode
				, OutletCode_Manufacturer
				, OutletCode_Warranty
				, OutletCode_Importer
				, OutletCode_GDD
				, PAGCode
				, PAGName
				, ImporterPartyID
				, Town
				, Region
				, FromDate
				, LanguageID
				, IP_SystemUser
			)
	    
				SELECT 
					  @Functions
					, @Manufacturer
					, @SuperNationalRegion
					, @BusinessRegion
					, @Market
					, @SubNationalTerritory							--v1.2
					, @SubNationalRegion
					, ISNULL(NULLIF(@CombinedDealer, ''), 'Independent')
					, @OutletName
					, @OutletName_NativeLanguage
					, @OutletName_Short
					, @OutletCode
					, @OutletCode_Manufacturer
					, @OutletCode_Warranty
					, @OutletCode_Importer
					, @OutletCode_GDD
					, @PAGCode
					, @PAGName
					, @ImporterPartyID
					, @Town
					, @Region
					, @FromDate
					, @LanguageID
					, @IP_SystemUser


	
		---------------------------------------------------------------------------------------------
		-- V1.4 Add in fix to set Market to DealerEquivalentMarket as drop-downs use Market
		---------------------------------------------------------------------------------------------
		--SELECT ND.Market, M.DealerTableEquivMarket, ISNULL(M.DealerTableEquivMarket,M.Market)
		UPDATE ND SET ND.Market = ISNULL(M.DealerTableEquivMarket,M.Market)
		FROM #NewDealers ND
		INNER JOIN dbo.Markets M ON M.Market = ND.Market
		---------------------------------------------------------------------------------------------	
	
	
		------------------------------------------------------------------------------------------
		-- VALIDATE THE DATA 
		------------------------------------------------------------------------------------------
	
	    
	    -- CHECK MANUFACTURER ENTRY AND ADD A FAILURE COMMENT IF IT IS MISSING

			UPDATE #NewDealers
				SET DataValidated = 0
				, ValidationFailureReasons = ValidationFailureReasons + 'Invalid Manufacturer; '
			WHERE ISNULL(Manufacturer, '') NOT IN 
				(
					SELECT DISTINCT 
						Manufacturer
					FROM DBO.DW_JLRCSPDealers
				)
	
		-- CHECK BUSINESSREGION AND ADD A FAILURE COMMENT IF IT IS MISSING OR DOESN'T EXIST IN THE DBO.REGION TABLE  -- v1.6
		
			UPDATE #NewDealers
				SET DataValidated = 0
				, ValidationFailureReasons = ValidationFailureReasons + 'Blank BusinessRegion; '
			WHERE ISNULL(BusinessRegion, '') = ''
			
			UPDATE #NewDealers
				SET DataValidated = 0
				, ValidationFailureReasons = ValidationFailureReasons + 'BusinessRegion does not exist in Sample.dbo.Regions table; '
			WHERE ISNULL(BusinessRegion, '') <> ''
			AND BusinessRegion NOT IN (SELECT Region FROM dbo.Regions)
			
			
			
		
		-- CHECK SUBNATIONAL TERRITORY AND ADD A FAILURE COMMENT IF IT IS MISSING					--v1.2
			
			UPDATE #NewDealers
				SET DataValidated = 0
				, ValidationFailureReasons = ValidationFailureReasons + 'Blank SubNationalTerritory; '
			WHERE ISNULL(SubNationalTerritory, '') = ''
	
	
		-- CHECK SUBNATIONAL REGION AND ADD A FAILURE COMMENT IF IT IS MISSING
		
			UPDATE #NewDealers
				SET DataValidated = 0
				, ValidationFailureReasons = ValidationFailureReasons + 'Blank SubNationalRegion; '
			WHERE ISNULL(SubNationalRegion, '') = ''
		
		-- CHECK DEALER NAME AND ADD A FAILURE COMMENT IF IT IS MISSING
		
			UPDATE #NewDealers
				SET DataValidated = 0
				, ValidationFailureReasons = ValidationFailureReasons + 'Blank OutletName; '
			WHERE ISNULL(OutletName, '') = ''
		
		-- CHECK DEALER CODE AND ADD A FAILURE COMMENT IF IT IS MISSING
		
			UPDATE #NewDealers
				SET DataValidated = 0
				, ValidationFailureReasons = ValidationFailureReasons + 'Blank OutletCode; '
			WHERE ISNULL(OutletCode, '') = ''
		
		-- CHECK FUNCTIONS AND ADD A FAILURE COMMENT IF IT IS MISSING
		
			UPDATE #NewDealers
				SET Functions = 'Aftersales'
			WHERE Functions = 'Service'
			
			UPDATE #NewDealers
				SET DataValidated = 0
				, ValidationFailureReasons = ValidationFailureReasons + 'Invalid Function; '
			WHERE ISNULL(Functions, '') NOT IN 
				(
					SELECT DISTINCT 
						OutletFunction
					FROM DBO.DW_JLRCSPDealers
				UNION
					SELECT 'Both'
				UNION
					SELECT 'All'
				)
			 
		-- CHECK TOWN AND ADD A FAILURE COMMENT IF IT IS MISSING
		
			UPDATE #NewDealers
				SET DataValidated = 0
				, ValidationFailureReasons = ValidationFailureReasons + 'Invalid Town; '
			WHERE ISNULL(Town, '') = ''	
		
		-- CHECK REGION AND ADD A FAILURE COMMENT IF IT IS MISSING
		
			UPDATE #NewDealers
				SET DataValidated = 0
				, ValidationFailureReasons = ValidationFailureReasons + 'Blank Region(State); '
			WHERE ISNULL(Region, '') = '' AND ISNULL(Market, '') = 'Australia'
		
		-- CHECK USERNAME AND ADD A FAILURE COMMENT IF IT IS MISSING
		
			UPDATE #NewDealers
				SET DataValidated = 0
				, ValidationFailureReasons = ValidationFailureReasons + 'Invalid User Credentials for Login: ' + IP_SystemUser + '; '
			WHERE ISNULL(IP_SystemUser, '') NOT IN 
				(
					SELECT UserName
					from DealerManagement.vwUsers
				)
	
	
		-- CHECK DEALER HEIRARCHY AS PROVIDED IN PARAMS IS VALID				--v1.2
			
			UPDATE ND
				SET DataValidated = 0
				, ValidationFailureReasons = ValidationFailureReasons + 'Dealer Heirarchy provided is invalid; '
			from #NewDealers ND
			LEFT JOIN (	-- Dealer Hierarchy
						SELECT sunr.SuperNationalRegion, 
								br.Region AS BusinessRegion ,
								m.Market AS Market,			-- V1.8 Uses Market rather than DealerEquivalentMarket
								snt.SubNationalTerritory,
								snr.SubNationalRegion
						FROM dbo.SuperNationalRegions sunr
						INNER JOIN dbo.Regions br ON br.SuperNationalRegionID = sunr.SuperNationalRegionID
						INNER JOIN dbo.Markets m ON m.RegionID = br.RegionID
						INNER JOIN dbo.SubNationalTerritories snt ON snt.MarketID = m.MarketID
						INNER JOIN dbo.SubNationalRegions snr ON snr.SubNationalTerritoryID = snt.SubNationalTerritoryID
					) DH ON DH.SuperNationalRegion	= @SuperNationalRegion	
						AND	DH.BusinessRegion		= @BusinessRegion		
						AND	DH.Market				= @Market				
						AND	DH.SubNationalTerritory	= @SubNationalTerritory	
						AND	DH.SubNationalRegion	= @SubNationalRegion
			WHERE DH.SubNationalRegion IS NULL  -- Where supplied params combo not found in dealer heirarchy
													 
													 
													 
		-- CHECK WE HAVEN'T LOADED THIS DEALER ALREAD@SubNationalRegion		Y
			
			UPDATE ND
				SET DataValidated = 0
				, ValidationFailureReasons = ValidationFailureReasons + 'Dealer successfully entered previously with fromdate ' + cast(ND.FromDate as nvarchar(20)) + '; '
			from #NewDealers ND
			INNER JOIN [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments DA ON ND.Manufacturer = DA.Manufacturer
														AND ND.Market = DA.Market
														AND ND.OutletName = DA.OutletName
														AND ND.OutletCode = DA.OutletCode
														AND ISNULL(ND.FromDate, '1 January 1900') <> ISNULL(ND.FromDate, '1 January 1900')	
			WHERE DA.IP_DataValidated = 1

			
		-- CHECK WE HAVEN'T LOADED A DEALER WITH SAME DEALERCODE IN SAME MARKET
		
			UPDATE ND
				SET DataValidated = 0
				, ValidationFailureReasons = ValidationFailureReasons + 'OutletCode ' + ND.OutletCode + ' already exists for this market; '
			from #NewDealers ND
			INNER JOIN [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments DA ON ND.Manufacturer = DA.Manufacturer
														AND ND.Market = DA.Market
														AND ND.Functions = DA.Functions
														AND ND.OutletCode = DA.OutletCode
			INNER JOIN dbo.DW_JLRCSPDealers D ON DA.IP_OutletPartyID = D.OutletPartyID				-- V1.3 Only include active dealers (i.e. ThroughDate is null)
														AND DA.Functions = D.OutletFunction
			WHERE DA.IP_DataValidated = 1
			AND D.ThroughDate IS NULL
		
		
		
	
		

		--  v1.2 : Not required -- UPDATE SUPERNATIONALREGION BASED ON PREVIOUSLY ENTRIES
		
			--UPDATE ND
				--SET SuperNationalRegion = snr.SuperNationalRegion
			--FROM #NewDealers ND
			--INNER JOIN 
				--(
					--SELECT DISTINCT
						--Market
						--, SuperNationalRegion
					--FROM Sample.dbo.DW_JLRCSPDealers
				--) SNR			
			--ON ND.Market = SNR.Market



		----------------------------------------------------------------------
		--- CHECK WHETHER INVALID LOAD REASONS and FAIL AND RETURN, IF THERE ARE  
		----------------------------------------------------------------------

		SELECT @ValidationFailureReasons = ValidationFailureReasons ,
				@DataValidated = DataValidated
		FROM #NewDealers 
		WHERE DataValidated <> 1 

		IF @DataValidated = 0
		BEGIN
		 RETURN 0   -- Not valid
		END



		------------------------------------------------------------------------
		------------------------------------------------------------------------
		------------------------------------------------------------------------


	BEGIN TRAN 


		----------------------------------------------------------------------
		-- INSERT DATA INTO DATA DEALER APPOINTMENTS TABLE 
		----------------------------------------------------------------------

		INSERT INTO [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments

			(
				  Functions
				, ManufacturerPartyID
				, Manufacturer
				, SuperNationalRegion
				, BusinessRegion					-- v1.6
				, Market
				, SubNationalTerritory				--v1.2
				, SubNationalRegion
				, CombinedDealer
				, OutletName
				, OutletName_Short
				, OutletName_NativeLanguage
				, OutletCode
				, OutletCode_Importer
				, OutletCode_Manufacturer
				, OutletCode_Warranty
				, OutletCode_GDD
				, PAGCode
				, PAGName
				, ImporterPartyID
				, Town
				, Region
				, CountryID
				, FromDate
				, LanguageID
				, IP_SystemUser
				, IP_DataValidated
				, IP_ValidationFailureReasons		
			)

				SELECT 
					DA.Functions
					, CASE DA.Manufacturer	
						WHEN 'Jaguar' THEN 2
						WHEN 'Land Rover' THEN 3
						ELSE 0
					END AS ManufacturerPartyID
					, DA.Manufacturer
					, DA.SuperNationalRegion
					, DA.BusinessRegion				-- v1.6
					, DA.Market
					, DA.SubNationalTerritory			-- v1.2
					, DA.SubNationalRegion
					, DA.CombinedDealer
					, DA.OutletName
					, DA.OutletName_Short
					, DA.OutletName_NativeLanguage
					, DA.OutletCode
					, DA.OutletCode_Importer
					, DA.OutletCode_Manufacturer
					, DA.OutletCode_Warranty
					, COALESCE(DA.OutletCode_GDD, DA.OutletCode_Manufacturer)
					, DA.PAGCode
					, DA.PAGName
					, DA.ImporterPartyID
					, DA.Town
					, DA.Region
					, M.CountryID AS CountryID 
					, DA.FromDate
					, DA.LanguageID
					, DA.IP_SystemUser
					, DA.DataValidated
					, DA.ValidationFailureReasons
				FROM #NewDealers DA
				LEFT JOIN dbo.Markets M ON CASE  
													WHEN DA.Market = 'UK' THEN 'United Kingdom' 																										
													WHEN DA.Market = 'Belux' THEN 'Belgium' --we set Belux dealers' CountryID as Belgium here
													WHEN DA.Market IN ('Russia' , 'Russia Federation') THEN 'Russian Federation'
													WHEN DA.Market = 'Palestine' THEN 'Occupied Palestinian Territory'		-- v1.6
													WHEN DA.Market = 'Moldova' THEN 'Republic of Moldova'					-- v1.7
													
													WHEN DA.Market = 'Ivory Coast' THEN N'Côte d''Ivoire'					-- v1.8, V1.10 Correction. Was initially shown as N'Côte, changed to N'Côte d''Ivoire'
													WHEN DA.Market = 'Congo, Republic' THEN 'Democratic Republic of the Congo'-- v1.8
													WHEN DA.Market = 'Tanzania' THEN 'United Republic of Tanzania'			-- v1.8
													WHEN DA.Market = 'Brunei' THEN 'Brunei Darussalam'						-- v1.9
														
													WHEN DA.Market = 'Falkland Islands' THEN 'Falkland Islands (Malvinas)'	-- v1.11
													WHEN DA.Market = 'Netherland Antilles' THEN 'Netherlands Antilles'		-- v1.11
													WHEN DA.Market = 'St. Kitts and Nevis' THEN 'Saint Kitts and Nevis'		-- v1.11

													WHEN DA.Market = 'Hong Kong' THEN 'Hong Kong Special Administrative Region Of China'	-- v1.11
													WHEN DA.Market = 'Taiwan' THEN 'Taiwan Province of China'								-- v1.11
													WHEN DA.Market = 'USA' THEN 'United States of America'					-- v1.12
											  ELSE DA.Market 
												  END  = M.Market
				
		


			
		----------------------------------------------------------------------
		-- DO THE DEALER APPOINTMENT
		----------------------------------------------------------------------

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
				FROM [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments DA
				INNER JOIN DealerManagement.vwUsers DU ON DU.UserName = 'OWAPAdmin'
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
			INNER JOIN DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID


		-- WRITE BACK THE CREATED AUDITID USING THE UNIQUE GUID/SESSIONID

			UPDATE AT
				SET AuditID = S.AuditID
			FROM #DistinctUsers DU
			INNER JOIN DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID
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
			INNER JOIN [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments DA ON AT.IP_DealerAppointmentID = DA.IP_DealerAppointmentID



		-- ASSIGN PARENT ORGANISATION AUDITITEMID IN DEALER APPOINTMENT TABLE
		
			UPDATE DA
				SET IP_OrganisationParentAuditItemID = OPAD.IP_OrganisationParentAuditItemID
			FROM [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments DA
			INNER JOIN
				(
					SELECT 
						OutletCode
						--, OutletName		-- V1.5
						, Market
						, Manufacturer
						, MIN(IP_AuditItemID) AS IP_OrganisationParentAuditItemID
					FROM [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments 
					WHERE IP_ProcessedDate IS NULL
					AND IP_DataValidated = 1
					GROUP BY
						OutletCode
						--, OutletName		-- V1.5
						, Market
						, Manufacturer
				) OPAD
			ON DA.OutletCode = OPAD.OutletCode
			--AND DA.OutletName = OPAD.OutletName		-- V1.5
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
			FROM dbo.DW_JLRCSPDealers D
			INNER JOIN 
				(SELECT MIN(D.OutletFunctionID) AS OutletFunctionID,
				DA.Manufacturer,
				DA.Market,
				DA.OutletCode
				--,DA.OutletName		-- V1.5
				FROM [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments DA
				INNER JOIN dbo.DW_JLRCSPDealers D ON DA.IP_OutletPartyID = D.OutletPartyID				
					AND (DA.Functions = D.OutletFunction OR (DA.Functions = 'Both' AND (D.OutletFunction = 'Sales' OR D.OutletFunction = 'Aftersales'))) -- V1.9
				WHERE DA.IP_DataValidated = 1
				AND DA.IP_ProcessedDate IS NOT NULL
				AND D.ThroughDate IS NULL								--V1.3 ONLY GET ACTIVE DEALERS
				GROUP BY DA.Manufacturer,
				DA.Market,
				DA.OutletCode
				--,DA.OutletName		-- V1.5
				) ED 
				ON D.Manufacturer = ED.Manufacturer
					AND D.Market = ED.Market
					AND D.OutletCode = ED.OutletCode
					--AND D.Outlet = ED.OutletName		-- V1.5
					AND D.OutletFunctionID = ED.OutletFunctionID
			INNER JOIN [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments DA ON D.OutletPartyID = DA.IP_OutletPartyID				
					AND (D.OutletFunction = DA.Functions OR ((D.OutletFunction = 'Sales' OR D.OutletFunction = 'Aftersales') AND DA.Functions = 'Both')) -- V1.9
			INNER JOIN [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments DAN ON DA.Manufacturer = DAN.Manufacturer
										AND DA.Market = DAN.Market
										AND DA.OutletCode = DAN.OutletCode
										--AND DA.OutletName = DAN.OutletName		-- V1.5
			WHERE DAN.IP_DataValidated = 1
			AND DAN.IP_ProcessedDate IS NULL
			------------------------------------------------------------------------------------------------------------------------------


		-- WRITE ORGANISATIONS (I.E. DEALERS) INTO SAMPLE MODEL
		
			INSERT INTO Party.vwDA_LegalOrganisations
				
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
					FROM [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments
					WHERE IP_DataValidated = 1
					AND IP_OutletPartyID IS NULL
					AND IP_ProcessedDate IS NULL

				
		-- WRITE NEWLY CREATED DEALERS PARTYID BACK TO APPOINTMENT TABLE
		
			UPDATE DA
				SET IP_OutletPartyID = AO.PartyID
			FROM [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments DA
			INNER JOIN [$(AuditDB)].Audit.Organisations AO ON DA.IP_AuditItemID = AO.AuditItemID
			WHERE IP_ProcessedDate IS NULL AND IP_DataValidated = 1
		
		-- ORGANISATION PARTIES NOW CREATED SO LETS NOW LOAD THESE PARTIES AS DEALERS

		-- CREATE TABLE TO RESOLVE THE TEXTUAL ENTRIES IN THE 'FUNCTIONS' COLUMN INTO IDS		
		-- v1.5 - Modified to include PreOwned and a RoleTypeFuntionName column for reference further on
		SELECT RoleTypeID, 
				CASE WHEN RoleType = 'Authorised Dealer (Sales)'		THEN 'Sales' 
					 WHEN RoleType = 'Authorised Dealer (Aftersales)'	THEN 'Aftersales'
					 WHEN RoleType = 'Authorised Dealer (PreOwned)'		THEN 'PreOwned'  
					 WHEN RoleType = 'Authorised Dealer (Bodyshop)'		THEN 'Bodyshop'  					 
				END AS RoleTypeFuntionName,
				CASE WHEN RoleType = 'Authorised Dealer (Sales)'		THEN 'Sales' 
					 WHEN RoleType = 'Authorised Dealer (Aftersales)'	THEN 'Aftersales'
					 WHEN RoleType = 'Authorised Dealer (PreOwned)'		THEN 'PreOwned'  
					 WHEN RoleType = 'Authorised Dealer (Bodyshop)'		THEN 'Bodyshop'  
				END AS Functions
		INTO #Functions
		FROM dbo.RoleTypes
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
					 WHEN RoleType = 'Authorised Dealer (PreOwned)'		THEN 'PreOwned'  
					 WHEN RoleType = 'Authorised Dealer (Bodyshop)'		THEN 'Bodyshop'  
				END AS RoleTypeFuntionName,
				'All' Functions
		FROM dbo.RoleTypes
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
		FROM dbo.RoleTypes
		WHERE RoleType IN (
							'Authorised Dealer (Sales)',
							'Authorised Dealer (Aftersales)'
						)

		
		-- V1.7 UPDATE @ImporterPartyID BASED ON vwBrandMarketQuestionnaireSampleMetadata VALUE
			UPDATE D SET D.ImporterPartyID = SM.DealerCodeOriginatorPartyID 
			FROM [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments D
				INNER JOIN #Functions AS F ON D.Functions = F.Functions
				LEFT JOIN dbo.Markets M ON D.Market = ISNULL(M.DealerTableEquivMarket,M.Market)
				LEFT JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata SM ON M.Market = SM.Market
																			AND D.Manufacturer = SM.Brand
																			AND F.Functions = SM.Questionnaire
			WHERE D.IP_ProcessedDate IS NULL
			AND D.IP_DataValidated = 1
			AND ISNULL(SM.DealerCodeOriginatorPartyID, 0) > 0
			AND ISNULL(SM.DealerCodeOriginatorPartyID, 0) NOT IN (2,3)
																			
																			
		-- INSERT DEALER NETWORKS RELATIONSHIPS - USE THE LOCAL LANGAUGE NAME FOR THE DELAER NAME COLUMN

			INSERT INTO Party.vwDA_DealerNetworks

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
				FROM [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments D
				INNER JOIN #Functions AS F ON D.Functions = F.Functions
				WHERE D.IP_ProcessedDate IS NULL
				AND D.IP_DataValidated = 1
				AND ISNULL(D.ImporterPartyID, 0) > 0
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
				FROM [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments AS D
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
				FROM [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments AS D
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
				FROM [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments AS D
				INNER JOIN #Functions AS F ON D.Functions = F.Functions
				WHERE D.IP_ProcessedDate IS NULL
				AND D.IP_DataValidated = 1
				AND D.ManufacturerPartyID IS NOT NULL
			
		-- ASSIGN PARENT POSTAL ADDRESS AUDITITEMID IN DEALER APPOINTMENT TABLE
			
			UPDATE D
				SET D.IP_AddressParentAuditItemID = P.AddressParentAuditItemID
			FROM [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments AS D
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
					FROM [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments AS D
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

			INSERT INTO ContactMechanism.vwDA_PostalAddresses
				
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
					FROM [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments AS D
					WHERE D.IP_ProcessedDate IS NULL
					AND D.IP_DataValidated = 1
					AND NULLIF(D.ContactMechanismID, 0) IS NULL
					AND ISNULL(D.CountryID, 0) > 0
		

		-- WRITE CONTACTMECHANISM BACK TO DEALER APPOINTMENT TABLE

				UPDATE D
					SET ContactMechanismID = APA.ContactMechanismID
				FROM [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments D
				INNER JOIN [$(AuditDB)].Audit.PostalAddresses APA ON D.IP_AuditItemID = APA.AuditItemID
				WHERE D.IP_ProcessedDate IS NULL
				AND D.IP_DataValidated = 1
				AND NULLIF(D.ContactMechanismID, 0) IS NULL
				AND ISNULL(D.CountryID, 0) > 0
			

		-- WRITE PARTYPOSTALADDDRESSES (I.E. TIE NEW DEALERS TO THEIR ADDRESSES)

			INSERT INTO ContactMechanism.vwDA_PartyPostalAddresses

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
					FROM [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments AS D
					WHERE D.IP_ProcessedDate IS NULL
					AND D.IP_DataValidated = 1
					AND D.ContactMechanismID IS NOT NULL 
					AND D.IP_OutletPartyID IS NOT NULL
					AND D.IP_AddressParentAuditItemID IS NOT NULL	-- V1.3 ONLY ADD IF NEW CONTACT MECHANISM
		
		-- 	ADD PARTY LANGUAGE IF ONE HAS BEEN SUPPLIED

			INSERT INTO Party.vwDA_PartyLanguages

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
					FROM [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments AS D
					WHERE D.IP_ProcessedDate IS NULL
					AND D.IP_DataValidated = 1
					AND ISNULL(D.LanguageID, 0) > 0
					AND D.IP_AddressParentAuditItemID IS NOT NULL	-- V1.3 ONLY ADD IF NEW CONTACT MECHANISM

					
		-- UPDATE DEALER DIMENSION TABLE WITH INITIAL HIERARCHY ENTRIES. N.B. WHEN A DEALER IS CREATED IT WILL TRANSFER TO ITSELF. 

			INSERT INTO DBO.DW_JLRCSPDealers

				(
					Manufacturer, 
					SupernationalRegion, 
					BusinessRegion,				
					Market, 
					SubNationalTerritory,			--v1.2
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
					PAGName
				)
				
					SELECT
						D.Manufacturer 		
						, LTRIM(RTRIM(D.SupernationalRegion)) AS SupernationalRegion 
						, LTRIM(RTRIM(D.BusinessRegion)) AS BusinessRegion 
						, LTRIM(RTRIM(D.Market)) AS Market 
						, LTRIM(RTRIM(D.SubnationalTerritory)) AS SubnationalTerritory				--v1.2 
						, LTRIM(RTRIM(D.SubnationalRegion)) AS SubnationalRegion 
						, LTRIM(RTRIM(D.CombinedDealer)) AS CombinedDealer
						, LTRIM(RTRIM(D.OutletName)) AS TransferDealer
						, LTRIM(RTRIM(D.OutletCode)) AS TransferDealerCode 
						, D.OutletName
						, D.OutletCode
						, F.RoleTypeFuntionName AS OutletFunction			
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
					FROM [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments AS D
					INNER JOIN #Functions AS F ON D.Functions = F.Functions
					WHERE D.IP_ProcessedDate IS NULL		
					AND D.IP_DataValidated = 1
					
		--INSERT RECORDS INTO TABLE CONTACTMECHANISM.DEALERCOUNTRIES
			
			INSERT INTO [Sample].ContactMechanism.DealerCountries
			SELECT DISTINCT 
					D.IP_OutletPartyID,
					dn.PartyIDTo,
					dn.RoleTypeIDFrom,
					dn.RoleTypeIDTo,
					dn.DealerCode,
					D.CountryID 
			FROM [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments D
			INNER JOIN Party.DealerNetworks dn on d.IP_OutletPartyID = dn.PartyIDFrom
			WHERE D.IP_ProcessedDate IS NULL
			AND D.IP_DataValidated = 1
			AND NOT EXISTS		-- V1.6 ADD WHERE ROW DOESN'T ALREADY EXIST
			(SELECT * FROM ContactMechanism.DealerCountries dc
			WHERE dc.PartyIDFrom = dn.PartyIDFrom AND dc.PartyIDTo = dn.PartyIDTo AND dc.RoleTypeIDFrom = dn.RoleTypeIDFrom AND dc.RoleTypeIDTo = dn.RoleTypeIDTo)
			--AND D.IP_AddressParentAuditItemID IS NOT NULL	-- V1.3 ONLY ADD IF NEW CONTACT MECHANISM -- V1.6 ADD FOR ALL CONTACT MECHANISMS				

		
		-- STAMP THE RECORDS AS PROCESSES
		
			UPDATE DA
				SET IP_ProcessedDate = GETDATE()
			FROM #AuditTrail AT
			INNER JOIN [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Appointments DA ON AT.AuditItemID = DA.IP_AuditItemID
			WHERE DA.IP_ProcessedDate IS NULL
			AND DA.IP_DataValidated = 1
		

	

		-- REBUILD FLATTENED DEALER TABLE 
	
		-- v1.1 
		 EXEC [$(ETLDB)].DealerManagement.uspDEALERS_JLRCSP_CreateFlatDealerList

		--- POPULATE RETURN VALUES 
		SELECT @ValidationFailureReasons = ValidationFailureReasons ,
			   @DataValidated = DataValidated
		FROM #NewDealers 


	COMMIT TRAN
	
	RETURN 1

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

	EXEC [Sample_Errors].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage

	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH
