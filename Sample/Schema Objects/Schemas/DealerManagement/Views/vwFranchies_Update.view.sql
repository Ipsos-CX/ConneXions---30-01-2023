CREATE VIEW [DealerManagement].[vwFranchises_Update]
	
AS 
	
/*
		Purpose:	View to Load Updated Franchises	
		
		Version		Developer			Date			Comment	
LIVE	1.0			Chris Ledger		2021-01-22		Created
LIVE	1.1			Chris Ledger		2021-01-28		Change Address Check from BINARY_CHECKSUM to TEXT and Adjust Market/Region
LIVE	1.2			Chris Ledger		2021-02-02		Use Group By to Avoid Duplicates with Update_FranchiseTradingTitle, Update_Address, Update_FranchiseCICode, Update_LocalLanguage
LIVE	1.3			Chris Ledger		2021-06-29		Task 517 - Add China Regions
LIVE	1.4         Ben King            2021-08-17      TASK 578 - China 3 digit code
LIVE	1.5         Ben King            2021-10-13      TASK 647 - 18361 - New Supernational and Business region for Japan
LIVE	1.6			Chris Ledger		2022-01-06		TASK 579 - Update LanguageID
LIVE	1.7			Chris Ledger		2022-01-17		TASK 751 - Add ApprovedUser
*/

SELECT 
	FL.[IP_ID],
	FL.[IP_AuditItemID],
	FL.[IP_OrganisationParentAuditItemID],
	FL.[IP_AddressParentAuditItemID],
	FL.[IP_OutletPartyID],
	FL.[IP_ManufacturerPartyID],
	FL.[IP_ImporterPartyID],
	FL.[IP_ContactMechanismID],
	FL.[IP_LanguageID],						-- V1.6
	FL.[IP_CountryID],
	FL.[IP_ProcessedDate],
	FL.[IP_DataValidated],
	FL.[ImportAuditID],
	FL.[ImportAuditItemID],
	FL.[ImportFileName],
	MAX(CASE WHEN FL.FranchiseTradingTitle <> F.FranchiseTradingTitle THEN 'Y' ELSE 'N' END) AS Update_FranchiseTradingTitle,
	MAX(CASE WHEN FL.FranchiseCICode <> F.FranchiseCICode THEN 'Y' ELSE 'N' END) AS Update_FranchiseCICode,
	MAX(CASE WHEN (FL.Address1 <> F.Address1) OR (FL.Address2 <> F.Address2) OR (FL.Address3 <> F.Address3) OR (FL.AddressTown <> F.AddressTown) OR (FL.AddressCountyDistrict <> F.AddressCountyDistrict) OR (FL.AddressPostcode <> F.AddressPostcode) THEN 'Y' ELSE 'N' END) AS Update_Address,		-- V1.1
	MAX(CASE WHEN ISNULL(FL.IP_LanguageID,0) <> ISNULL(F.LanguageID,0) THEN 'Y' ELSE 'N' END) AS Update_LocalLanguage,		-- V1.1
	RD.[RDsRegionID],
	BR.[BusinessRegionID],
	COALESCE(FR.[FranchiseRegionID],FR1.[FranchiseRegionID]) AS [FranchiseRegionID],		-- V1.3
	FM.[FranchiseMarketID],
	SZ.[SalesZoneID],
	AZ.[AuthorisedRepairerZoneID],
	BZ.[BodyshopZoneID],
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
	ISNULL(FM.[FranchiseMarket],'') AS FranchiseMarket,										-- V1.1
	FL.[MarketNumber] AS FranchiseMarketNumber,
	ISNULL(COALESCE(FR.[FranchiseRegion],FR1.[FranchiseRegion]),'') AS FranchiseRegion,		-- V1.1 V1.3
	COALESCE(FR1.[FranchiseRegionNumber],FL.[RegionNumber]) AS FranchiseRegionNumber,		-- V1.3
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
	FL.[ChinaDMSRetailerCode],	-- V1.4
	FL.[ApprovedUser]			-- V1.7
FROM DealerManagement.Franchises_Load FL
	INNER JOIN dbo.FranchiseTypes FT ON FL.FranchiseType = FT.FranchiseType
	INNER JOIN dbo.FranchiseTypesOutletFunctions FTOF ON FT.FranchiseTypeID = FTOF.FranchiseTypeID
	INNER JOIN dbo.Franchises F ON FL.[10CharacterCode] = F.[10CharacterCode]
									AND FL.IP_CountryID = F.CountryID
									AND FL.IP_OutletPartyID = F.OutletPartyID
									AND FTOF.OutletFunctionID = F.OutletFunctionID
	LEFT JOIN dbo.Languages L ON FL.LocalLanguage1 = L.Language
	--LEFT JOIN dbo.RDsRegions RD ON RD.RDsRegion = FL.RDsRegion
	--LEFT JOIN dbo.BusinessRegions BR ON BR.BusinessRegion = FL.BusinessRegion
	LEFT JOIN dbo.RDsRegions RD ON RD.RDsRegion = FL.RDsRegion
									AND CASE FL.IP_CountryID WHEN 105 THEN FL.IP_CountryID ELSE 0 END = ISNULL(RD.CountryID,0)			-- V1.5
    LEFT JOIN dbo.BusinessRegions BR ON BR.BusinessRegion = FL.BusinessRegion
										AND CASE FL.IP_CountryID WHEN 105 THEN FL.IP_CountryID ELSE 0 END = ISNULL(BR.CountryID,0)		-- V1.5
	LEFT JOIN dbo.FranchiseRegions FR ON FR.FranchiseRegionNumber = FL.RegionNumber
										AND FR.CountryID = FL.IP_CountryID
										AND FR.CountryID = 221													-- V1.3
	LEFT JOIN dbo.FranchiseRegions FR1 ON FR1.FranchiseRegion = FL.Region										-- V1.3
										AND FR1.CountryID = FL.IP_CountryID										-- V1.3
										AND FR1.CountryID = 43													-- V1.3
	LEFT JOIN dbo.FranchiseMarkets FM ON FM.FranchiseMarketNumber = FL.MarketNumber
										AND FM.CountryID = FL.IP_CountryID										-- V1.1
	LEFT JOIN dbo.SalesZones SZ ON SZ.SalesZone = FL.SalesZone
										AND SZ.SalesZoneCode = FL.SalesZoneCode
										AND SZ.CountryID = FL.IP_CountryID
	LEFT JOIN dbo.AuthorisedRepairerZones AZ ON AZ.AuthorisedRepairerZone = FL.AuthorisedRepairerZone
										AND AZ.AuthorisedRepairerZoneCode = FL.AuthorisedRepairerZoneCode
										AND AZ.CountryID = FL.IP_CountryID
	LEFT JOIN dbo.BodyshopZones BZ ON BZ.BodyshopZone = FL.BodyshopZone
										AND BZ.BodyshopZoneCode = FL.BodyshopZoneCode
										AND BZ.CountryID = FL.IP_CountryID
WHERE EXISTS (	SELECT IP_ID FROM DealerManagement.Franchises_Load FL1
					INNER JOIN dbo.FranchiseTypes FT ON FL1.FranchiseType = FT.FranchiseType
					INNER JOIN dbo.FranchiseTypesOutletFunctions FTOF ON FT.FranchiseTypeID = FTOF.FranchiseTypeID
					INNER JOIN dbo.Markets M ON FL1.IP_CountryID = M.CountryID
					INNER JOIN dbo.Brands B ON FL1.Brand = B.Brand
					INNER JOIN dbo.BrandMarketQuestionnaireMetadata QM ON QM.BrandID = B.BrandID
																		AND QM.MarketID = M.MarketID
																		AND QM.QuestionnaireID = FTOF.QuestionnaireID
					INNER JOIN dbo.Franchises F1 ON FL1.[10CharacterCode] = F1.[10CharacterCode]
														AND FL1.IP_CountryID = F1.CountryID
														AND FL1.IP_OutletPartyID = F1.OutletPartyID
														AND FTOF.OutletFunctionID = F1.OutletFunctionID
				WHERE F1.[10CharacterCode] IS NOT NULL
					AND FL1.IP_ID = FL.IP_ID
					AND	(	HASHBYTES('MD5', CONCAT(ISNULL(FL1.[IP_LanguageID],0),'|',RD.[RDsRegionID],'|',BR.[BusinessRegionID],'|',COALESCE(FR.[FranchiseRegionID],FR1.[FranchiseRegionID]),'|',FM.[FranchiseMarketID],'|',SZ.[SalesZoneID],'|',AZ.[AuthorisedRepairerZoneID],'|',BZ.[BodyshopZoneID],'|',FL1.[RDsRegion],'|',FL1.[BusinessRegion],'|',FL1.[DistributorCountryCode],'|',FL1.[DistributorCountry],'|',FL1.[DistributorCICode],'|',FL1.[DistributorName],'|',FL1.[FranchiseCountryCode],'|',FL1.[FranchiseCountry],'|',FL1.[JLRNumber],'|',FL1.[RetailerLocality],'|',FL1.[Brand],'|',FL1.[FranchiseCICode],'|',FL1.[FranchiseTradingTitle],'|',FL1.[FranchiseShortName],'|',FL1.[RetailerGroup],'|',FL1.[FranchiseType],'|',FL1.[Address1],'|',FL1.[Address2],'|',FL1.[Address3],'|',FL1.[AddressTown],'|',FL1.[AddressCountyDistrict],'|',FL1.[AddressPostcode],'|',FL1.[AddressLatitude],'|',FL1.[AddressLongitude],'|',FL1.[AddressActivity],'|',FL1.[Telephone],'|',FL1.[Email],'|',FL1.[URL],'|',FL1.[FranchiseStatus],'|',FL1.[FranchiseStartDate],'|',FL1.[FranchiseEndDate],'|',FL1.[LegacyFlag],'|',FL1.[10CharacterCode],'|',FL1.[FleetandBusinessRetailer],'|',FL1.[SVO],'|',ISNULL(FM.[FranchiseMarket],''),'|',FL1.[MarketNumber],'|',ISNULL(COALESCE(FR.[FranchiseRegion],FR1.[FranchiseRegion]),''),'|',COALESCE(FR1.[FranchiseRegionNumber],FL.[RegionNumber]),'|',FL1.[SalesZone],'|',FL1.[SalesZoneCode],'|',FL1.[AuthorisedRepairerZone],'|',FL1.[AuthorisedRepairerZoneCode],'|',FL1.[BodyshopZone],'|',FL1.[BodyshopZoneCode],'|',FL1.[LocalTradingTitle1],'|',FL1.[LocalLanguage1],'|',FL1.[LocalTradingTitle2],'|',FL1.[LocalLanguage2],'|',FL1.[ChinaDMSRetailerCode],'|',FL1.[ApprovedUser]))		-- V1.3, V1.4, V1.6, V1.7
							<> 
							HASHBYTES('MD5', CONCAT(ISNULL(F1.[LanguageID],0),'|',F1.[RDsRegionID],'|',F1.[BusinessRegionID],'|',F1.[FranchiseRegionID],'|',F1.[FranchiseMarketID],'|',F1.[SalesZoneID],'|',F1.[AuthorisedRepairerZoneID],'|',F1.[BodyshopZoneID],'|',F1.[RDsRegion],'|',F1.[BusinessRegion],'|',F1.[DistributorCountryCode],'|',F1.[DistributorCountry],'|',F1.[DistributorCICode],'|',F1.[DistributorName],'|',F1.[FranchiseCountryCode],'|',F1.[FranchiseCountry],'|',F1.[JLRNumber],'|',F1.[RetailerLocality],'|',F1.[Brand],'|',F1.[FranchiseCICode],'|',F1.[FranchiseTradingTitle],'|',F1.[FranchiseShortName],'|',F1.[RetailerGroup],'|',F1.[FranchiseType],'|',F1.[Address1],'|',F1.[Address2],'|',F1.[Address3],'|',F1.[AddressTown],'|',F1.[AddressCountyDistrict],'|',F1.[AddressPostcode],'|',F1.[AddressLatitude],'|',F1.[AddressLongitude],'|',F1.[AddressActivity],'|',F1.[Telephone],'|',F1.[Email],'|',F1.[URL],'|',F1.[FranchiseStatus],'|',F1.[FranchiseStartDate],'|',F1.[FranchiseEndDate],'|',F1.[LegacyFlag],'|',F1.[10CharacterCode],'|',F1.[FleetandBusinessRetailer],'|',F1.[SVO],'|',F1.[FranchiseMarket],'|',F1.[FranchiseMarketNumber],'|',F1.[FranchiseRegion],'|',F1.[FranchiseRegionNumber],'|',F1.[SalesZone],'|',F1.[SalesZoneCode],'|',F1.[AuthorisedRepairerZone],'|',F1.[AuthorisedRepairerZoneCode],'|',F1.[BodyshopZone],'|',F1.[BodyshopZoneCode],'|',F1.[LocalTradingTitle1],'|',F1.[LocalLanguage1],'|',F1.[LocalTradingTitle2],'|',F1.[LocalLanguage2],'|',F1.[ChinaDMSRetailerCode],'|',F1.[ApprovedUser])) -- V1.4, V1.6, V1.7
						))
GROUP BY FL.[IP_ID],
	FL.[IP_AuditItemID],
	FL.[IP_OrganisationParentAuditItemID],
	FL.[IP_AddressParentAuditItemID],
	FL.[IP_OutletPartyID],
	FL.[IP_ManufacturerPartyID],
	FL.[IP_ImporterPartyID],
	FL.[IP_ContactMechanismID],
	FL.[IP_LanguageID],											-- V1.6
	FL.[IP_CountryID],
	FL.[IP_ProcessedDate],
	FL.[IP_DataValidated],
	FL.[ImportAuditID],
	FL.[ImportAuditItemID],
	FL.[ImportFileName],
	RD.[RDsRegionID],
	BR.[BusinessRegionID],
	COALESCE(FR.[FranchiseRegionID],FR1.[FranchiseRegionID]),	-- V1.3
	FM.[FranchiseMarketID],
	SZ.[SalesZoneID],
	AZ.[AuthorisedRepairerZoneID],
	BZ.[BodyshopZoneID],
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
	ISNULL(FM.[FranchiseMarket],''),
	FL.[MarketNumber],
	ISNULL(COALESCE(FR.[FranchiseRegion],FR1.[FranchiseRegion]),''),	-- V1.3
	COALESCE(FR1.[FranchiseRegionNumber],FL.[RegionNumber]),			-- V1.3
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
	FL.[ChinaDMSRetailerCode],	-- V1.4
	FL.[ApprovedUser]			-- V1.7

GO