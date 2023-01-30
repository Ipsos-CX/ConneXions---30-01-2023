CREATE NONCLUSTERED INDEX [IX_GermanyRetailers_OutletPartyID]
ON [GermanyRedFlagReport].[GermanyRetailers] ([OutletPartyID], [OutletFunctionID])
	INCLUDE ([Market], [Region], [Dealer], [Brand], [BrandID], [Report Week], [Report Date])
