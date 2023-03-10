CREATE TRIGGER [DealerManagement].[TR_I_vwDA_DEALERS_JLRCSP_UPDATE_SubNationalTerritory] 
ON [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_SubNationalTerritory]

INSTEAD OF INSERT

AS

	--	Purpose:	Validate data entered via the MS Access dealer database and mark it for processing
	--
	--
	-- Version			Date			Developer			Comment
	-- 1.0				12/10/2016		Chris Ross			Created (copied from SubNationRegion)
	-- 1.1				10/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases

	-- SET LOCAL CONNECTION PROPERTIES

	SET NOCOUNT ON
	SET XACT_ABORT ON

	BEGIN TRAN

	-- VALIDATE INSERTED RECORDS
		-- N.B. USER DEFINED DATA TYPES DO NOT APPEAR TO HAVE SCOPE INSIDE TRIGGER THEREFORE DATATYPES EXPLICIT IN TABLE DEFINITION

		CREATE TABLE #SubNationalTerritoryChange

			(
				IP_SubNationalTerritoryChangeID INT IDENTITY(1,1) NOT NULL
				, OutletFunction VARCHAR(25)
				, Manufacturer NVARCHAR(510)
				, Market NVARCHAR(255)
				, SubNationalTerritory NVARCHAR(255)
				, NewSubNationalTerritory NVARCHAR(255)
				, NewSubNationalRegion NVARCHAR(255)
				, OutletCode NVARCHAR(10)
				, IP_OutletPartyID INT
				, IP_SystemUser VARCHAR(50)
				, IP_DataValidated BIT DEFAULT(0)
				, IP_ValidationFailureReasons VARCHAR(1000) DEFAULT('')
			)
		
		
			INSERT INTO #SubNationalTerritoryChange

				(
					OutletFunction
					, Manufacturer
					, Market
					, OutletCode
					, SubNationalTerritory
					, NewSubNationalTerritory
					, NewSubNationalRegion
					, IP_SystemUser
				)

					SELECT DISTINCT
						OutletFunction
						, Manufacturer
						, Market
						, OutletCode
						, SubNationalTerritory
						, NewSubNationalTerritory
						, NewSubNationalRegion
						, IP_SystemUser
					FROM inserted


	-- CHECK MANUFACTURER, ADD VALIDATION FAILURE REASON IF IT DOESN'T EXIST

		UPDATE #SubNationalTerritoryChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Manufacturer; '
		WHERE ISNULL(Manufacturer, '') NOT IN (SELECT DISTINCT Manufacturer	FROM [$(SampleDB)].dbo.DW_JLRCSPDealers)
	
	
	-- CHECK MARKET, ADD VALIDATION FAILURE REASON IF IT DOESN'T EXIST

		UPDATE #SubNationalTerritoryChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Market; '
		WHERE ISNULL(Market, '') NOT IN (SELECT DISTINCT Market FROM [$(SampleDB)].dbo.DW_JLRCSPDealers)
	
	
	-- CHECK OUTLETCODE IS POPULATED, ADD VALIDATEION FAILURE REASON IF IT DOESN'T EXIST
	
		UPDATE #SubNationalTerritoryChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Blank DealerCode; '
		WHERE ISNULL(OutletCode, '') = ''
	

	-- CHECK USERNAME TO ENSURE USER HAS PERMISSION TO MAKE CHANGES

		UPDATE #SubNationalTerritoryChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid User Credentials for Login: ' + IP_SystemUser + '; '
		WHERE ISNULL(IP_SystemUser, '') NOT IN (SELECT UserName FROM [$(SampleDB)].DealerManagement.vwUsers)


	-- CHECK FOR A VALID OUTLETFUNCTION, MANUFACTURER, MARKET AND DEALERCODE COMBINATION AND CHECK THERE IS ONLY ONE OUTLETPARTYID

	-- WRITE OUTLET PARTY ID TO A LOAD TABLE

	CREATE TABLE #CurrentDealers
	
		(
			OutletFunction NVARCHAR(25)
			, Manufacturer NVARCHAR(255)
			, Market NVARCHAR(255)
			, OutletCode NVARCHAR(255)
			, OutletPartyID INT
			, ThroughDateSet INT				-- v1.1
		)


	INSERT INTO #CurrentDealers

		(
			OutletFunction
			, Manufacturer
			, Market
			, OutletCode
			, OutletPartyID
			, ThroughDateSet
		)

			SELECT DISTINCT 
				OutletFunction
				, Manufacturer
				, Market
				, OutletCode
				, OutletPartyID
				,CASE WHEN GETDATE() < ISNULL(throughdate , '20991231')  
					THEN 0 ELSE 1 END AS ThroughDateSet     -- v1.1
			FROM [$(SampleDB)].dbo.DW_JLRCSPDealers
			--GROUP BY 
			--	OutletFunction
			--	, Manufacturer
			--	, Market
			--	, OutletCode
			--	, OutletPartyID



	-- CHECK FOR A VALID OUTLETFUNCTION, MANUFACTURER, MARKET AND DEALERCODE COMBINATION. IF MORE THAN CURRENT DEALER ONE FLAG IT UP
		UPDATE SNRC
			SET IP_DataValidated = 0,
				IP_ValidationFailureReasons = SNRC.IP_ValidationFailureReasons + 'More than one OutletPartyID exists; '
		FROM #SubNationalTerritoryChange SNRC
		INNER JOIN #CurrentDealers CD ON SNRC.OutletFunction = CD.OutletFunction
										AND SNRC.Manufacturer = CD.Manufacturer
										AND SNRC.Market =  CD.Market
										AND SNRC.OutletCode = CD.OutletCode
										AND CD.ThroughDateSet = 0			-- v1.1 - Only current "active" dealers
			INNER JOIN 
			
				(
					SELECT 
						SNRC1.IP_SubNationalTerritoryChangeID
					FROM #SubNationalTerritoryChange SNRC1
					INNER JOIN #CurrentDealers CD1 ON SNRC1.OutletFunction = CD1.OutletFunction
											AND SNRC1.Manufacturer = CD1.Manufacturer
											AND SNRC1.Market = CD1.Market
											AND SNRC1.OutletCode = CD1.OutletCode
											AND CD1.ThroughDateSet = 0
					GROUP BY SNRC1.IP_SubNationalTerritoryChangeID
					HAVING COUNT(CD1.OutletPartyID) > 1
				) X 
			ON SNRC.IP_SubNationalTerritoryChangeID = X.IP_SubNationalTerritoryChangeID


		-- SET OUTLET PARTYID VALUE AND THE RECORD AS VALID IF NOT PREVIOUSLY FLAGGED INVALID 
		UPDATE SNRC
			SET IP_DataValidated = CASE WHEN SNRC.IP_ValidationFailureReasons = '' THEN 1 ELSE 0 END,
			IP_OutletPartyID = CD.OutletPartyID
		FROM #SubNationalTerritoryChange SNRC
		INNER JOIN #CurrentDealers CD ON SNRC.OutletFunction = CD.OutletFunction		
										AND SNRC.Manufacturer = CD.Manufacturer
										AND SNRC.Market =  CD.Market
										AND SNRC.OutletCode = CD.OutletCode
		

	
	
	-- CHECK FOR INVALID OUTLETFUNCTION, MANUFACTURER, MARKET AND DEALERCODE COMBINATIONS
	
		UPDATE SNRC
			SET IP_DataValidated = 0,
				IP_ValidationFailureReasons = SNRC.IP_ValidationFailureReasons + 'Invalid OutletFunction, Manufacturer, Market and DealerCode combination; '
		FROM #SubNationalTerritoryChange SNRC
		LEFT JOIN #CurrentDealers CD ON SNRC.OutletFunction = CD.OutletFunction
									AND SNRC.Manufacturer = CD.Manufacturer
									AND SNRC.Market = CD.Market
									AND SNRC.OutletCode = CD.OutletCode
		WHERE CD.OutletPartyID IS NULL
	
		-- CHECK FOR INVALID TERRITORY/REGION COMBINATION WITHIN MARKET  (we have already ascertained that the market is correct for the Dealer in the prev check)
	
		UPDATE SNRC
			SET IP_DataValidated = 0,
				IP_ValidationFailureReasons = SNRC.IP_ValidationFailureReasons + 'Invalid SubNationalTerritory/Region combination within current Dealer Hierarchy for Market; '
		FROM #SubNationalTerritoryChange SNRC
		LEFT JOIN (	-- Dealer Hierarchy
						SELECT 	COALESCE(m.DealerTableEquivMarket, m.Market) AS Market,
								snt.SubNationalTerritory,
								snr.SubNationalRegion
						FROM [$(SampleDB)].dbo.Markets m 
						INNER JOIN [$(SampleDB)].dbo.SubNationalTerritories snt ON snt.MarketID = m.MarketID
						INNER JOIN [$(SampleDB)].dbo.SubNationalRegions snr ON snr.SubNationalTerritoryID = snt.SubNationalTerritoryID
					) DH ON DH.Market				= SNRC.Market				
						AND	DH.SubNationalTerritory	= SNRC.NewSubNationalTerritory	
						AND	DH.SubNationalRegion	= SNRC.NewSubNationalRegion
			WHERE DH.SubNationalRegion IS NULL  -- Where supplied params combo not found in dealer heirarchy
	
	
	
	
	-- INSERT DATA INTO LOADING TABLE

		INSERT INTO DealerManagement.DEALERS_JLRCSP_UPDATE_SubNationalTerritory

			(
				ID
				, OutletFunction
				, Manufacturer
				, Market
				, SubNationalTerritory
				, NewSubNationalTerritory
				, NewSubNationalRegion
				, OutletCode
				, IP_OutletPartyID
				, IP_SystemUser
				, IP_DataValidated
				, IP_ValidationFailureReasons
				
			)
			
			SELECT DISTINCT
				 D.ID
				, SNRC.OutletFunction
				, SNRC.Manufacturer
				, SNRC.Market
				, SNRC.SubNationalTerritory
				, SNRC.NewSubNationalTerritory
				, SNRC.NewSubNationalRegion
				, SNRC.OutletCode
				, SNRC.IP_OutletPartyID
				, SNRC.IP_SystemUser
				, SNRC.IP_DataValidated
				, SNRC.IP_ValidationFailureReasons
			FROM #SubNationalTerritoryChange SNRC
			LEFT JOIN [$(SampleDB)].DBO.DW_JLRCSPDealers D ON D.OutletPartyID = SNRC.IP_OutletPartyID
													AND D.OutletFunction = SNRC.OutletFunction
		
			DROP TABLE #SubNationalTerritoryChange
			DROP TABLE #CurrentDealers
		
	COMMIT TRAN