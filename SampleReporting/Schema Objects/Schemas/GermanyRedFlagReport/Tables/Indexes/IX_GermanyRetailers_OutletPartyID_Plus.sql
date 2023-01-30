CREATE NONCLUSTERED INDEX [IX_GermanyRetailers_OutletPartyID_Plus]
ON [GermanyRedFlagReport].[GermanyRetailers] ([OutletFunctionID],[OutletPartyID],[Report Date])
	INCLUDE ([Market],[Region],[Brand],[BrandID],[Report Week])