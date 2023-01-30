CREATE TRIGGER [DealerManagement].[TR_I_vwDA_DEALERS_JLRCSP_Appointments] ON  [DealerManagement].[vwDA_DEALERS_JLRCSP_Appointments]
INSTEAD OF INSERT

AS 

	--	Purpose:	Populate the Dealer Appointment table checking the source columns to ensure that they comply
	--
	--	Version			Developer			Date			Comment
	--	1.0				Martin Riverol		23/04/2012		Created
	--	1.1				Martin Riverol		30/04/2012		Default CombinedDealer = 'Independent' if no value supplied
	--  1.2				Martin Riverol		10/06/2012		Derive the SuperNationalRegion from previously created dealers
	--  1.3				Martin Riverol		12/04/2013		Add GDD Code
	--  1.4				Ali Yuksel			13/01/2014		Market matching amended to get CountryID in DEALERS_JLRCSP_Appointments (Belux and Russia added) 
	--  1.5				Peter Doyle			30/10/2014		Typo fixed
	--	1.6				Chris Ross			25/02/2015		BUG 11026 - Add in BusinessRegion and check it is a valid entry in the dbo.Regions table
	--																	Also add in Palestine market equivalent on Market lookup.
	--	1.7				Eddie Thomas		25/03/2015		Market matching amended to get CountryID in DEALERS_JLRCSP_Appointments (Moldova) 		
	--  1.8				Eddis Thomas		25/03/2015		Market matching amended to get CountryID in DEALERS_JLRCSP_Appointments (Ivory Coast, Tanzania & Republic of Congo) 	
	--  1.9				Chris Ledger		04/11/2015		Market matching amended to get CountryID in DEALERS_JLRCSP_Appointments (Brunei) 	
	--  1.10			Chris Ross			08/02/2016		BUG 12038 - Add in "ALL" option under Function check.
	--  1.11			Chris Ledger		01/04/2016		Market matching amended to get CountryID in DEALERS_JLRCSP_Appointments (Falkland Islands to Taiwan) 	
	--  1.12			Eddie Thomas 		30/08/2016		Market matching amended to get CountryID in DEALERS_JLRCSP_Appointments (USA) 	
	--  1.13			Chris Ross			12/10/2016		BUG 13171 - Add in new SubNationalTerritory column + verify that dealer hierarchy provided is valid
	--	1.14			Chris Ledger		24/02/2017		BUG 13621 - When checking for the same DealerCode only check current dealers (to help fix for changing DealerIDs) 
	--  1.15			Chris Ledger		10/01/2020		BUG 15372 - Fix Hard coded references to databases

	-- DISABLE COUNTS
	SET NOCOUNT ON

	-- DECLARE LOCAL VARIABLES
	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

	-- CHECK AND WRITE DEALER ENTRIES
	BEGIN TRY
	
		-- CREATE A WORKING TABLE
		CREATE TABLE #NewDealers
		
			(
				[Functions] [nvarchar](25) NOT NULL
				, [Manufacturer] NVARCHAR(510) NULL
				, [SuperNationalRegion] NVARCHAR(150) NULL
				, [BusinessRegion] NVARCHAR(150) NULL				-- v1.6
				, [Market] NVARCHAR(255) NOT NULL
				, [SubNationalTerritory] NVARCHAR(255) NULL			-- 1.13
				, [SubNationalRegion] NVARCHAR(255) NULL
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
				, SubNationalTerritory				-- v1.13
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
					Functions
					, Manufacturer
					, SuperNationalRegion
					, BusinessRegion
					, Market
					, SubNationalTerritory				--v1.13
					, SubNationalRegion
					, ISNULL(NULLIF(CombinedDealer, ''), 'Independent')
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
				FROM inserted
	    
	    -- CHECK MANUFACTURER ENTRY AND ADD A FAILURE COMMENT IF IT IS MISSING

			UPDATE #NewDealers
				SET DataValidated = 0
				, ValidationFailureReasons = ValidationFailureReasons + 'Invalid Manufacturer; '
			WHERE ISNULL(Manufacturer, '') NOT IN 
				(
					SELECT DISTINCT 
						Manufacturer
					FROM [$(SampleDB)].DBO.DW_JLRCSPDealers
				)
	
		-- CHECK BUSINESSREGION AND ADD A FAILURE COMMENT IF IT IS MISSING OR DOESN'T EXIST IN THE DBO.REGION TABLE  -- v1.6
		
			UPDATE #NewDealers
				SET DataValidated = 0
				, ValidationFailureReasons = ValidationFailureReasons + 'Blank BusinessRegion; '
			WHERE ISNULL(BusinessRegion, '') = ''
			
			UPDATE #NewDealers
				SET DataValidated = 0
				, ValidationFailureReasons = ValidationFailureReasons + 'BusinessRegion does not exist in dbo.Regions table; '
			WHERE ISNULL(BusinessRegion, '') <> ''
			AND BusinessRegion NOT IN (SELECT Region FROM [$(SampleDB)].dbo.Regions)
			
			
	
		-- CHECK SUBNATIONAL TERRITORY AND ADD A FAILURE COMMENT IF IT IS MISSING					--v1.13
		
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
					FROM [$(SampleDB)].DBO.DW_JLRCSPDealers
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
					from [$(SampleDB)].DealerManagement.vwUsers
				)


		-- CHECK DEALER HEIRARCHY AS PROVIDED IN PARAMS IS VALID				--v1.2
			
			UPDATE ND
				SET DataValidated = 0
				, ValidationFailureReasons = ValidationFailureReasons + 'Dealer Heirarchy provided is invalid; '
			from #NewDealers ND
			LEFT JOIN (	-- Dealer Hierarchy
						SELECT sunr.SuperNationalRegion, 
								br.Region AS BusinessRegion ,
								COALESCE(m.DealerTableEquivMarket, m.Market) AS Market,
								snt.SubNationalTerritory,
								snr.SubNationalRegion
						FROM [$(SampleDB)].dbo.SuperNationalRegions sunr
						INNER JOIN [$(SampleDB)].dbo.Regions br ON br.SuperNationalRegionID = sunr.SuperNationalRegionID
						INNER JOIN [$(SampleDB)].dbo.Markets m ON m.RegionID = br.RegionID
						INNER JOIN [$(SampleDB)].dbo.SubNationalTerritories snt ON snt.MarketID = m.MarketID
						INNER JOIN [$(SampleDB)].dbo.SubNationalRegions snr ON snr.SubNationalTerritoryID = snt.SubNationalTerritoryID
					) DH ON DH.SuperNationalRegion	= ND.SuperNationalRegion	
						AND	DH.BusinessRegion		= ND.BusinessRegion		
						AND	DH.Market				= ND.Market				
						AND	DH.SubNationalTerritory	= ND.SubNationalTerritory	
						AND	DH.SubNationalRegion	= ND.SubNationalRegion
			WHERE DH.SubNationalRegion IS NULL  -- Where supplied params combo not found in dealer heirarchy

			
		-- CHECK WE HAVEN'T LOADED THIS DEALER ALREADY
			
			UPDATE ND
				SET DataValidated = 0
				, ValidationFailureReasons = ValidationFailureReasons + 'Dealer successfully entered previously with fromdate ' + cast(ND.FromDate as nvarchar(20)) + '; '
			from #NewDealers ND
			INNER JOIN DealerManagement.DEALERS_JLRCSP_Appointments DA ON ND.Manufacturer = DA.Manufacturer
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
			INNER JOIN DealerManagement.DEALERS_JLRCSP_Appointments DA ON ND.Manufacturer = DA.Manufacturer
														AND ND.Market = DA.Market
														AND ND.Functions = DA.Functions
														AND ND.OutletCode = DA.OutletCode
			INNER JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON DA.IP_OutletPartyID = D.OutletPartyID				-- V1.13 Only include active dealers (i.e. ThroughDate is null)
														AND DA.Functions = D.OutletFunction
			WHERE DA.IP_DataValidated = 1
			AND D.ThroughDate IS NULL
		

		-- v1.13 : Not required -- UPDATE SUPERNATIONALREGION BASED ON PREVIOUSLY ENTRIES
		
			--UPDATE ND
				--SET SuperNationalRegion = snr.SuperNationalRegion
			--FROM #NewDealers ND
			--INNER JOIN 
				--(
					--SELECT DISTINCT
						--Market
						--, SuperNationalRegion
					--FROM [$(SampleDB)].dbo.DW_JLRCSPDealers
				--) SNR			
			--ON ND.Market = SNR.Market

		-- INSERT DATA INTO DATA DEALER APPOINTMENTS TABLE 


		INSERT INTO DealerManagement.DEALERS_JLRCSP_Appointments

			(
				Functions
				, ManufacturerPartyID
				, Manufacturer
				, SuperNationalRegion
				, BusinessRegion					-- v1.6
				, Market
				, SubNationalTerritory				--v1.13
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
					, DA.SubNationalTerritory			--v1.13
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
				--FROM DealerManagement.vwDA_DEALERS_JLRCSP_Appointments DA
				FROM #NewDealers DA
				LEFT JOIN [$(SampleDB)].dbo.Markets M ON CASE  
													WHEN DA.Market = 'UK' THEN 'United Kingdom' 																										
													WHEN DA.Market = 'Belux' THEN 'Belgium' --we set Belux dealers' CountryID as Belgium here
													WHEN DA.Market IN ('Russia' , 'Russia Federation') THEN 'Russian Federation'
													WHEN DA.Market = 'Palestine' THEN 'Occupied Palestinian Territory'		-- v1.6
													WHEN DA.Market = 'Moldova' THEN 'Republic of Moldova'					-- v1.7
													
													WHEN DA.Market = 'Ivory Coast' THEN N'Côte' 							-- v1.8
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
	END TRY


	BEGIN CATCH
		-- CATCH ANY ERRORS AND WRITE THEM TO THE ERRORS DATABASE
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