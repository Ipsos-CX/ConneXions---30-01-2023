CREATE NONCLUSTERED INDEX [IX_Franchises_Load_FranchiseType]
	ON [DealerManagement].[Franchises_Load] ([FranchiseType])
	INCLUDE ([IP_ID],[IP_OutletPartyID],[IP_ManufacturerPartyID],[IP_CountryID],[RDsRegion],[BusinessRegion],[FranchiseTradingTitle],[10CharacterCode],[MarketNumber],[Region],[RegionNumber],[SalesZone],[SalesZoneCode],[AuthorisedRepairerZone],[AuthorisedRepairerZoneCode],[BodyshopZone],[BodyshopZoneCode])
