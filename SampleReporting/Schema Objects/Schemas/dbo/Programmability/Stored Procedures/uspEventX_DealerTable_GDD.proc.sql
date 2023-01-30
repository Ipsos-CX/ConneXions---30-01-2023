CREATE PROCEDURE [dbo].[uspEventX_DealerTable_GDD]

AS

	/* INITIAL CREATE EVENTX_DEALERLIST SCRIPT */

	/* THE NATURAL KEY ON THIS TABLE IS MADE OF... 

		SampleDealerPartyID
		DealerPartyID
		Survey
		Brand
	*/
	
	/*
		Purpose:	Table to store distinct list of global dealers
			
		Release		Version		Date			Developer			Comment
		LIVE		1.0			??/??/????		Martin Riverol		Created
		LIVE		1.1			30/05/2013		Martin Riverol		Add Town information to output
		LIVE		1.2			07/11/2013		Martin Riverol		BUG 9645: Trim Manufacturer field of whitespace 
		LIVE		1.3			11/11/2014		Eddie Thomas		BUG 10916 - Added MENA markets to filter
		LIVE		1.4			26/02/2015		Chris Ross			BUG 11026 - Update the filter to use the EventXDealerList flag on Sample.dbo.Markets to determine 
																	whether to include the market in the table.
																	
		LIVE		1.5			05/05/2016		Eddie Thomas		Macedonia dealers not exported
		LIVE		1.6			24/08/2016		Eddie Thomas		Town information not being exporting correctly
		LIVE		1.7			14/10/2016		Chris Ross			BUG 13171 - Add in SubNationalTerritory and IncSubNationalTerritoryInHierarchy columns.
																	Remove the DealerTableEquiv fix for Macedonia as have reset the DealerTableEquiv to NULL in dbo.Markets.
																	Also removed superfluous select statement from the end of the proc.
																	
		LIVE		1.8			13/11/2017		Chris Ledger		BUG 14365: Add SVODealer & FleetDealer
		LIVE		1.9			17/11/2017		Chris Ledger		BUG 14347: Exclude InterCompanyOwnUseDealer
		LIVE		1.10		07/12/2017		Chris Ledger		BUG 14365: Change SVODealer & FleetDealer to Text Fields
		LIVE		1.11		31/05/2018		Chris Ledger		BUG 14752: Add LostLeadProvider field
		LIVE		1.12		20/05/2018		Ben King			BUG 15117: Remove Markets/Surveys without responses
		LIVE		1.13		15/01/2020		Chris Ledger 		BUG 15372: Fix cases
		LIVE		1.14		17/01/2020		Chris Ledger		BUG 16793: Add Dealer10DigitCode
		LIVE		1.15		19/01/2021		Ben King			BUG 18065: Update Event X DP file to include new JLR fields
		LIVE		1.16		08/02/2021		Ben King			BUG 18105: Event - X update, Town field reference & remove no response filter
		LIVE		1.17        18/08/2021      Ben King            TASK 578 - China 3 digit code
		LIVE		1.18		07/10/2021      Ben King            TASK 643 - Add new column for Medallia - ReportingRetailerName
		LIVE		1.19        08/11/2021      Ben King            TASK 692 - 18390 - Adding Cyprus - North to the hierarchy
		LIVE		1.20        12/11/2021      Ben King            TASK 464 - Historic data  Hierarchy file - terminated retailers
		LIVE		1.21		18/01/2022		Ben King			TASK 750 - New APO column in FIMs - Ben
		LIVE	    1.22		11/02/2022		Ben King			TASK 786 - EventX extract - add Google IDs 
		                                                                       (NB: Change live but not populated from FIMs file. Field not output in EventX. Left in for future use)
		LIVE		1.23		12/07/2022		Eddie Thomas		TASK 873 - Change the value in the Survey column to be LRE instead of Experience

*/

	TRUNCATE TABLE dbo.EventX_DealerTable_GDD

	INSERT INTO dbo.EventX_DealerTable_GDD
	
		(
			SampleDealerPartyID
			, DealerPartyID
			, Survey
			, Brand
			, SuperNationalRegion
			, BusinessRegion
			, Market
			, SubNationalTerritory			-- v1.7
			, Region
			, DealerGroup
			, DealerCode_GDD
			, DealerCode
			, DealerName
			, Town
			, PAGCode		
			, PAGName
			, IncSubNationalTerritoryInHierarchy
			, SVODealer						-- V1.8
			, FleetDealer					-- V1.8
			, LostLeadProvider				-- V1.11
			, Dealer10DigitCode				-- V1.14
			, DealerStatus					-- v1.15
			, OutletFunctionID				-- V1.15
			, ChinaDMSRetailerCode          -- V1.17
			, ReportingRetailerName         -- V1.18
			, ApprovedUser					-- V1.21
			, GoogleCID                     -- V1.21
		)

	SELECT DISTINCT
			D.OutletPartyID AS SampleDealerPartyID
			, D.TransferPartyID AS DealerPartyID
			, CASE D.OutletFunction		
					WHEN 'Experience' THEN 'LRE'		--V1.23
					ELSE D.OutletFunction
			  END	AS Survey
			, LTRIM(RTRIM(D.Manufacturer)) AS Brand
			, D.SuperNationalRegion
			, D.BusinessRegion	
			--, D.Market	
			, COALESCE(D.AlternateMarketEventX, D.Market) AS Market	-- v1.19	
			, D.SubNationalTerritory
			, D.SubNationalRegion AS Region
			, D.CombinedDealer AS DealerGroup
			, D.TransferDealerCode_GDD AS DealerCode_GDD
			, D.TransferDealerCode AS DealerCode
			, D.TransferDealer AS DealerName
			, ISNULL(A.Town, '') 
			, ISNULL(D.PAGCode,'')		
			, ISNULL(D.PAGName,'')
			, 0 AS IncSubNationalTerritoryInHierarchy
			, CASE SVODealer	WHEN 1 THEN 'SVO Retailer'
								ELSE 'Non-SVO Retailer' END AS SVODealer						-- V1.8 V1.10
			, CASE FleetDealer	WHEN 1 THEN 'Fleet Retailer'
								ELSE 'Non-Fleet Retailer' END AS FleetDealer					-- V1.8 V1.10
			, '' AS LostLeadProvider															-- V1.11
			, ISNULL(D.Dealer10DigitCode, '') AS Dealer10DigitCode								-- V1.14
			, CASE							                                                    -- V1.15
				WHEN D.ThroughDate IS NULL THEN 'Active'
				ELSE 'Terminated'
			  END AS DealerStatus
			, D.OutletFunctionID
			, D.ChinaDMSRetailerCode          -- V1.17
			, D.ReportingRetailerName         -- V1.18
			, D.ApprovedUser					  -- V1.21
			, D.GoogleCID --V1.22
	FROM [$(SampleDB)].dbo.DW_JLRCSPDealers D
	LEFT JOIN 
		(
			SELECT PCM.PartyID, Town
			FROM [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM 
			INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON PCM.ContactMechanismID = PA.ContactMechanismID
			INNER JOIN 
				(
					SELECT PartyID, MAX(PA.ContactMechanismID) AS ContactMechanismID
					FROM [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM 
					INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON PCM.ContactMechanismID = PA.ContactMechanismID
					GROUP BY PCM.PartyID
				) X
			ON PCM.PartyID = X.PartyID 
			AND PCM.ContactMechanismID = X.ContactMechanismID
							
		) A
	ON D.TransferPartyID = A.PartyID
	WHERE D.Market IN (SELECT DISTINCT COALESCE(DealerTableEquivMarket, Market) AS Market				-- v1.7 -- Removed conditional Macedonia market fix
					 FROM [$(SampleDB)].dbo.Markets 
					 WHERE EventXDealerList = 1 
					 AND Market NOT IN ('United States of America','Canada')
					 )
	AND D.InterCompanyOwnUseDealer = 0																-- V1.9	
			

	UNION	--v1.6 ADD IN NORTH AMERICA  DEALERS


	SELECT DISTINCT
			D.OutletPartyID AS SampleDealerPartyID
			, D.TransferPartyID AS DealerPartyID
			, D.OutletFunction AS Survey
			, LTRIM(RTRIM(D.Manufacturer)) AS Brand
			, D.SuperNationalRegion
			, D.BusinessRegion	
			, D.Market																			
			, D.SubNationalTerritory
			, D.SubNationalRegion AS Region
			, D.CombinedDealer AS DealerGroup
			, D.TransferDealerCode_GDD AS DealerCode_GDD
			, D.TransferDealerCode AS DealerCode
			, D.TransferDealer AS DealerName
			, ISNULL(A.Town, '') 
			, ISNULL(D.PAGCode,'')		
			, ISNULL(D.PAGName,'')
			, 0 AS IncSubNationalTerritoryInHierarchy
			, CASE SVODealer	WHEN 1 THEN 'SVO Retailer'
								ELSE 'Non-SVO Retailer' END AS SVODealer						-- V1.8 V1.10
			, CASE FleetDealer	WHEN 1 THEN 'Fleet Retailer'
								ELSE 'Non-Fleet Retailer' END AS FleetDealer					-- V1.8 V1.10
			, CASE ISNULL(LLR.LostSalesProvider,'NO LLA')	WHEN 'Shift' THEN ''
															WHEN 'NO LLA' THEN ''
															ELSE LLR.LostSalesProvider END AS LostLeadProvider	-- V1.11		
			, ISNULL(D.Dealer10DigitCode, '') AS Dealer10DigitCode								-- V1.14
			, CASE							                                                    -- V1.15
				WHEN D.ThroughDate IS NULL THEN 'Active'
				ELSE 'Terminated'
			  END AS DealerStatus
			, D.OutletFunctionID
			, D.ChinaDMSRetailerCode          -- V1.17
			, D.ReportingRetailerName         -- V1.18
			, D.ApprovedUser					  -- V1.21
			, D.GoogleCID --V1.22
	FROM [$(SampleDB)].dbo.DW_JLRCSPDealers D
	LEFT JOIN -- V1.16 START OF REPLACED JOIN
		(
			SELECT PCM.PartyID, Town
			FROM [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM 
			INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON PCM.ContactMechanismID = PA.ContactMechanismID
			INNER JOIN 
				(
					SELECT PartyID, MAX(PA.ContactMechanismID) AS ContactMechanismID
					FROM [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM 
					INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON PCM.ContactMechanismID = PA.ContactMechanismID
					GROUP BY PCM.PartyID
				) X
			ON PCM.PartyID = X.PartyID 
			AND PCM.ContactMechanismID = X.ContactMechanismID
							
		) A
	ON D.TransferPartyID = A.PartyID -- V1.16 END OF REPLACED JOIN
	LEFT JOIN [$(SampleDB)].dbo.Markets M ON D.Market = ISNULL(M.DealerTableEquivMarket,M.Market)	-- V1.11
	LEFT JOIN [$(SampleDB)].ContactMechanism.Countries C ON M.CountryID = C.CountryID				-- V1.11
	LEFT JOIN [$(ETLDB)].Lookup.LostLeadsAgencyStatus LLR ON D.OutletCode_GDD = LLR.CICode	-- V1.11		
																AND C.ISOAlpha2 = LLR.Market	-- V1.11
																AND D.OutletFunction = 'Sales'	-- V1.11
	WHERE D.Market IN (	SELECT COALESCE(DealerTableEquivMarket, Market) AS Market 
						FROM [$(SampleDB)].dbo.Markets 
						WHERE EventXDealerList = 1 AND 
						Market IN ('United States of America','Canada')
					)
	AND D.InterCompanyOwnUseDealer = 0														-- V1.9
			
			
	-- Add in the IncSubNationalTerritoryInHierarchy flag from the Markets table			-- v1.7
	UPDATE x
		SET x.IncSubNationalTerritoryInHierarchy = 1
	FROM dbo.EventX_DealerTable_GDD x
	INNER JOIN [$(SampleDB)].dbo.Markets m ON x.Market = COALESCE(m.DealerTableEquivMarket, m.Market)
	WHERE m.IncSubNationalTerritoryInHierarchy = 1
	
	
	
	--V1.12 - remove Markets/Surveys without responses
	--V1.16 - removed filter!
	--	;WITH MARKET_RESPONSES_CTE (Market, CountryID, EventType)
	--AS
	--(
	--	SELECT DISTINCT COALESCE(M.DealerTableEquivMarket, M.Market) AS Market, M.CountryID,
	--	CASE WHEN CD.EventType = 'Service' THEN 'Aftersales'
	--		 ELSE CD.EventType
	--	END AS EventType
	--	FROM [$(SampleDB)].dbo.Markets M
	--	INNER JOIN [$(SampleDB)].Meta.CaseDetails CD ON CD.CountryID = M.CountryID
	--	INNER JOIN [$(SampleDB)].Event.Cases C ON C.CaseID = CD.CaseID
	--	WHERE C.ClosureDate IS NOT NULL
	--)	
	--DELETE G
	--FROM dbo.EventX_DealerTable_GDD G
	--LEFT JOIN MARKET_RESPONSES_CTE M2 ON M2.Market = G.Market
	--								 AND M2.EventType = G.Survey 
	--WHERE M2.Market IS NULL AND G.Market NOT IN ('Montenegro') --exclude these markets from deletion


	----V1.18 START
	--	;WITH CTE_Dealer10DigitCode (Dealer10DigitCode)
	--	AS
	--		(
	--			SELECT Dealer10DigitCode
	--			FROM dbo.EventX_DealerTable_GDD
	--			WHERE DealerStatus <> 'Terminated'
	--		)
	--,CTE_Sales (Dealer10DigitCode, SalesDealerName)
	--	AS
	--		(
	--			SELECT Dealer10DigitCode, DealerName
	--			FROM dbo.EventX_DealerTable_GDD
	--			WHERE Survey = 'Sales' 
	--			AND DealerStatus <> 'Terminated'
	--		)
	--,CTE_AfterSales (Dealer10DigitCode, AfterSalesDealerName)
	--	AS
	--		(
	--			SELECT Dealer10DigitCode, DealerName
	--			FROM dbo.EventX_DealerTable_GDD
	--			WHERE Survey = 'AfterSales' 
	--			AND DealerStatus <> 'Terminated'
	--		)
	--,CTE_PreOwned (Dealer10DigitCode, PreOwnedDealerName)
	--	AS
	--		(
	--			SELECT Dealer10DigitCode, DealerName
	--			FROM dbo.EventX_DealerTable_GDD
	--			WHERE Survey = 'PreOwned' 
	--			AND DealerStatus <> 'Terminated'
	--		)
	--,CTE_BodyShop (Dealer10DigitCode, BodyShopDealerName)
	--	AS
	--		(
	--			SELECT Dealer10DigitCode, DealerName
	--			FROM dbo.EventX_DealerTable_GDD
	--			WHERE Survey = 'BodyShop' 
	--			AND DealerStatus <> 'Terminated'
	--		)
	--SELECT DISTINCT
	--	D.Dealer10DigitCode, 
	--	S.SalesDealerName,
	--	A.AfterSalesDealerName,
	--	P.PreOwnedDealerName,
	--	B.BodyShopDealerName,
	--	CASE WHEN SalesDealerName IS NOT NULL THEN SalesDealerName
	--	     WHEN SalesDealerName IS NULL AND AfterSalesDealerName IS NOT NULL THEN AfterSalesDealerName
	--	     WHEN SalesDealerName IS NULL AND AfterSalesDealerName IS NULL AND PreOwnedDealerName IS NOT NULL THEN PreOwnedDealerName
	--	     WHEN SalesDealerName IS NULL AND AfterSalesDealerName IS NULL AND PreOwnedDealerName IS NULL AND BodyShopDealerName IS NOT NULL THEN BodyShopDealerName
	--	END AS ReportingRetailerName
	--INTO #ReportingRetailerName
	--FROM CTE_Dealer10DigitCode D
	--LEFT JOIN CTE_Sales S ON D.Dealer10DigitCode = S.Dealer10DigitCode
	--LEFT JOIN CTE_AfterSales A ON D.Dealer10DigitCode = A.Dealer10DigitCode
	--LEFT JOIN CTE_PreOwned P ON D.Dealer10DigitCode = P.Dealer10DigitCode
	--LEFT JOIN CTE_BodyShop B ON D.Dealer10DigitCode = B.Dealer10DigitCode


	--UPDATE G
	--SET G.ReportingRetailerName = CASE 
	--									WHEN R.ReportingRetailerName IS NOT NULL THEN R.ReportingRetailerName
	--									ELSE G.DealerName
	--							  END
	--FROM dbo.EventX_DealerTable_GDD G
	--LEFT JOIN #ReportingRetailerName R ON G.Dealer10DigitCode = R.Dealer10DigitCode

	--V1.18 END ---

	--V1.15
	DELETE E
	FROM dbo.EventX_DealerTable_GDD E
	INNER JOIN [$(SampleDB)].dbo.Markets M ON E.Market = ISNULL(M.DealerTableEquivMarket, M.Market)
	WHERE M.FranchiseCountryType <> 'Core'
	OR M.FranchiseCountryType IS NULL

	
	--V1.15
	UPDATE E
	SET E.JLR_RDsRegion = F.RDsRegion,
		E.JLR_BusinessRegion = F.BusinessRegion,
		E.JLR_DistributorCountryCode = F.DistributorCountryCode,
		E.JLR_DistributorCountry = F.DistributorCountry,
		E.JLR_DistributorCICode = F.DistributorCICode,
		E.JLR_DistributorName = F.DistributorName,
		E.JLR_FranchiseCountryCode = F.FranchiseCountryCode,
		E.JLR_FranchiseCountry = F.FranchiseCountry,
		E.JLR_JLRNumber = F.JLRNumber,
		E.JLR_RetailerLocality = F.RetailerLocality,
		E.JLR_Brand = F.Brand,
		E.JLR_FranchiseCICode = F.FranchiseCICode,
		E.JLR_FranchiseTradingTitle = F.FranchiseTradingTitle,
		E.JLR_FranchiseShortName = F.FranchiseShortName,
		E.JLR_RetailerGroup = F.RetailerGroup,
		E.JLR_FranchiseType = F.FranchiseType,
		E.JLR_Address1 = F.Address1,
		E.JLR_Address2 = F.Address2,
		E.JLR_Address3 = F.Address3,
		E.JLR_AddressTown = F.AddressTown,
		E.JLR_AddressCountyDistrict = F.AddressCountyDistrict,
		E.JLR_AddressPostcode = F.AddressPostcode,
		E.JLR_AddressLatitude = F.AddressLatitude,
		E.JLR_AddressLongitude = F.AddressLongitude,
		E.JLR_AddressActivity = F.AddressActivity,
		E.JLR_Telephone = F.Telephone,
		E.JLR_Email = F.Email,
		E.JLR_URL = F.URL,
		E.JLR_FranchiseStatus = F.FranchiseStatus,
		E.JLR_FranchiseStartDate = F.FranchiseStartDate,
		E.JLR_FranchiseEndDate = F.FranchiseEndDate,
		E.JLR_LegacyFlag = F.LegacyFlag,
		E.JLR_10CharacterCode = F.[10CharacterCode],
		E.JLR_FleetandBusinessRetailer = F.FleetandBusinessRetailer,
		E.JLR_SVO = F.SVO,
		E.JLR_Market = F.FranchiseMarket,
		E.JLR_MarketNumber = F.FranchiseMarketNumber,
		E.JLR_Region = F.FranchiseRegion,
		E.JLR_RegionNumber = F.FranchiseRegionNumber,
		E.JLR_SalesZone = F.SalesZone,
		E.JLR_SalesZoneCode = F.SalesZoneCode,
		E.JLR_AuthorisedRepairerZone = F.AuthorisedRepairerZone,
		E.JLR_AuthorisedRepairerZoneCode = F.AuthorisedRepairerZoneCode,
		E.JLR_BodyshopZone = F.BodyshopZone,
		E.JLR_BodyshopZoneCode = F.BodyshopZoneCode,
		E.JLR_LocalTradingTitle1 = F.LocalTradingTitle1,
		E.JLR_LocalLanguage1 = F.LocalLanguage1,
		E.JLR_LocalTradingTitle2 = F.LocalTradingTitle2,
		E.JLR_LocalLanguage2 = F.LocalLanguage2
	--SELECT DISTINCT E.*
	FROM dbo.EventX_DealerTable_GDD E
	INNER JOIN [$(SampleDB)].dbo.Franchises F ON E.Dealer10DigitCode = F.[10CharacterCode]
                                  AND E.SampleDealerPartyID = F.OutletPartyID
                                  AND E.OutletFunctionID = F.OutletFunctionID
	INNER JOIN [$(SampleDB)].dbo.Markets M ON F.CountryID = M.CountryID
                                  AND E.Market = COALESCE(M.DealerTableEquivMarket, M.Market)		



	--V1.15 - Removes original Dealer10DigitCode that do not correspond with Franchise File
	--Removed after V1.20
	--UPDATE dbo.EventX_DealerTable_GDD
	--SET Dealer10DigitCode = ''
	--WHERE JLR_RDsRegion IS NULL
	--AND DealerStatus = 'Terminated'

	--V1.20
	UPDATE E
	SET E.Dealer10DigitCode = ''
	FROM dbo.EventX_DealerTable_GDD E
	WHERE E.SampleDealerPartyID <> E.DealerPartyID
	AND E.JLR_BusinessRegion IS NULL
	AND E.Dealer10DigitCode NOT LIKE '%IPSOS%'


	
	