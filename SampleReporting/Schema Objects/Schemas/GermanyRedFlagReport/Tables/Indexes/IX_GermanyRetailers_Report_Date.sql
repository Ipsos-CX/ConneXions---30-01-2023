CREATE NONCLUSTERED INDEX [IX_GermanyRetailers_Report_Date]
ON [GermanyRedFlagReport].[GermanyRetailers] ([Report Date])
	INCLUDE ([Market],[Brand],[BrandID],[OutletFunctionID],[OutletPartyID],[Report Week])
GO