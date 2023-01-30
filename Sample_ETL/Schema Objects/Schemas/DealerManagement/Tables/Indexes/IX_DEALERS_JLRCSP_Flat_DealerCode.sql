CREATE NONCLUSTERED INDEX [IX_DEALERS_JLRCSP_Flat_DealerCode]
	ON [DealerManagement].[DEALERS_JLRCSP_Flat] ([DealerCode],[OutletPartyID],[OutletFunction])
	INCLUDE ([BusinessRegion],[ManufacturerDealerCode])