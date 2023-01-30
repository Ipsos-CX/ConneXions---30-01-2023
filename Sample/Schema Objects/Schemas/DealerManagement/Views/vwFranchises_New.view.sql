CREATE VIEW [DealerManagement].[vwFranchises_New]
	
AS 
	
/*

		Purpose:	View to Load New Franchises

		Version		Developer			Date			Comment	
LIVE	1.0			Chris Ledger		2021-01-08		Created
LIVE	1.1			Chris Ledger		2021-01-13		Add contraint that valid BrandMarketQuestionnaireMetadata data exists
LIVE	1.2			Chris Ledger		2021-01-19		Change region join to refer to RegionNumber which is populated whereas Region sometimes isn't
LIVE	1.3			Chris Ledger		2021-01-19		Incorporate further changes to Region/Market/Zones
LIVE	1.4			Chris Ledger		2021-01-28		More Changes to Region/Market
LIVE	1.5			Chris Ledger		2021-06-29		Task 517 - Add China Regions
LIVE	1.6         Ben King            2021-08-17      TASK 578 - China 3 digit code
LIVE	1.7         Ben King            2021-10-13      TASK 647 - 18361 - New Supernational and Business region for Japan
LIVE	1.8			Chris Ledger		2022-01-17		TASK 751 - Add ApprovedUser
*/

SELECT 
	FL.[IP_ID],
	FL.[IP_AuditItemID],
	FL.[IP_OrganisationParentAuditItemID],
	FL.[IP_AddressParentAuditItemID],
	FL.[IP_OutletPartyID],
	FL.[IP_ContactMechanismID],
	FL.[IP_ManufacturerPartyID],
	FL.[IP_ImporterPartyID],
	FL.[IP_LanguageID],
	FL.[IP_CountryID],
	FL.[IP_ProcessedDate],
	FL.[IP_DataValidated],
	FL.[ImportAuditID],
	FL.[ImportAuditItemID],
	FL.[ImportFileName],
	RD.[RDsRegionID],
	BR.[BusinessRegionID],
	COALESCE(FR.[FranchiseRegionID],FR1.[FranchiseRegionID]) AS [FranchiseRegionID],	-- V1.3 V1.5
	FM.[FranchiseMarketID],																-- V1.3	
	SZ.[SalesZoneID],																	-- V1.3
	AZ.[AuthorisedRepairerZoneID],														-- V1.3
	BZ.[BodyshopZoneID],																-- V1.3
	FL.[RDsRegion],
	FL.[BusinessRegion],
	FL.[DistributorCountryCode],
	FL.[DistributorCountry],
	FL.[DistributorCICode],
	FL.[DistributorName],
	FL.[FranchiseCountryCode],
	FL.[FranchiseCountry],
	FL.[JLRNumber],
	FL.[RetailerLocality],
	FL.[Brand],
	FL.[FranchiseCICode],
	FL.[FranchiseTradingTitle],
	FL.[FranchiseShortName],
	FL.[RetailerGroup],
	FL.[FranchiseType],
	FL.[Address1],
	FL.[Address2],
	FL.[Address3],
	FL.[AddressTown],
	FL.[AddressCountyDistrict],
	FL.[AddressPostcode],
	FL.[AddressLatitude],
	FL.[AddressLongitude],
	FL.[AddressActivity],
	FL.[Telephone],
	FL.[Email],
	FL.[URL],
	FL.[FranchiseStatus],
	FL.[FranchiseStartDate],
	FL.[FranchiseEndDate],
	FL.[LegacyFlag],
	FL.[10CharacterCode],
	FL.[FleetandBusinessRetailer],
	FL.[SVO],
	ISNULL(FM.[FranchiseMarket],'') AS FranchiseMarket,										-- V1.3 V1.4
	FL.[MarketNumber] AS FranchiseMarketNumber,												-- V1.3
	ISNULL(COALESCE(FR.[FranchiseRegion],FR1.[FranchiseRegion]),'') AS FranchiseRegion,		-- V1.2 V1.3 V1.4 V1.5
	COALESCE(FR1.[FranchiseRegionNumber],FL.[RegionNumber]) AS FranchiseRegionNumber,		-- V1.3 V1.5
	FL.[SalesZone],
	FL.[SalesZoneCode],
	FL.[AuthorisedRepairerZone],
	FL.[AuthorisedRepairerZoneCode],
	FL.[BodyshopZone],
	FL.[BodyshopZoneCode],
	FL.[LocalTradingTitle1],
	FL.[LocalLanguage1],
	FL.[LocalTradingTitle2],
	FL.[LocalLanguage2],
	FL.[ChinaDMSRetailerCode],		-- V1.6
	FL.[ApprovedUser]				-- V1.8
FROM DealerManagement.Franchises_Load FL
	--LEFT JOIN dbo.RDsRegions RD ON RD.RDsRegion = FL.RDsRegion
	--LEFT JOIN dbo.BusinessRegions BR ON BR.BusinessRegion = FL.BusinessRegion
	LEFT JOIN dbo.RDsRegions RD ON RD.RDsRegion = FL.RDsRegion
										AND CASE FL.IP_CountryID WHEN 105 THEN FL.IP_CountryID ELSE 0 END = ISNULL(RD.CountryID,0)		-- V1.7
	LEFT JOIN dbo.BusinessRegions BR ON BR.BusinessRegion = FL.BusinessRegion
										AND CASE FL.IP_CountryID WHEN 105 THEN FL.IP_CountryID ELSE 0 END = ISNULL(BR.CountryID,0)		-- V1.7
	LEFT JOIN dbo.FranchiseRegions FR ON FR.FranchiseRegionNumber = FL.RegionNumber							-- V1.2 V1.3
										AND FR.CountryID = FL.IP_CountryID									-- V1.4
										AND FR.CountryID = 221												-- V1.5
	LEFT JOIN dbo.FranchiseRegions FR1 ON FR1.FranchiseRegion = FL.Region									-- V1.5
										AND FR1.CountryID = FL.IP_CountryID									-- V1.5
										AND FR1.CountryID = 43												-- V1.5
	LEFT JOIN dbo.FranchiseMarkets FM ON FM.FranchiseMarketNumber = FL.MarketNumber							-- V1.3
										AND FM.CountryID = FL.IP_CountryID									-- V1.4
	LEFT JOIN dbo.SalesZones SZ ON SZ.SalesZone = FL.SalesZone												-- V1.3
										AND SZ.SalesZoneCode = FL.SalesZoneCode								-- V1.4
										AND SZ.CountryID = FL.IP_CountryID									-- V1.4
	LEFT JOIN dbo.AuthorisedRepairerZones AZ ON AZ.AuthorisedRepairerZone = FL.AuthorisedRepairerZone		-- V1.3
										AND AZ.AuthorisedRepairerZoneCode = FL.AuthorisedRepairerZoneCode
										AND AZ.CountryID = FL.IP_CountryID									-- V1.4
	LEFT JOIN dbo.BodyshopZones BZ ON BZ.BodyshopZone = FL.BodyshopZone										-- V1.3
										AND BZ.BodyshopZoneCode = FL.BodyshopZoneCode						-- V1.4
										AND BZ.CountryID = FL.IP_CountryID									-- V1.4
WHERE EXISTS (	SELECT IP_ID FROM DealerManagement.Franchises_Load FL1
					INNER JOIN dbo.FranchiseTypes FT ON FL1.FranchiseType = FT.FranchiseType
					INNER JOIN dbo.FranchiseTypesOutletFunctions FTOF ON FT.FranchiseTypeID = FTOF.FranchiseTypeID
					INNER JOIN dbo.Markets M ON FL1.IP_CountryID = M.CountryID
					INNER JOIN dbo.Brands B ON FL1.Brand = B.Brand
					INNER JOIN dbo.BrandMarketQuestionnaireMetadata QM ON QM.BrandID = B.BrandID
																		AND QM.MarketID = M.MarketID
																		AND QM.QuestionnaireID = FTOF.QuestionnaireID
					LEFT JOIN dbo.Franchises F ON FL1.[10CharacterCode] = F.[10CharacterCode]
														AND FL1.IP_CountryID = F.CountryID
														AND FTOF.OutletFunctionID = F.OutletFunctionID
				WHERE F.[10CharacterCode] IS NULL
					AND ((FTOF.OutletFunction = 'PreOwned' AND ISNULL(FL1.ApprovedUser,'') <> 'No') OR FTOF.OutletFunction <> 'PreOwned')	-- V1.8 Only add 'PreOwned' FranchiseType if ApprovedUser <> 'NO'
					AND FL1.IP_ID = FL.IP_ID)