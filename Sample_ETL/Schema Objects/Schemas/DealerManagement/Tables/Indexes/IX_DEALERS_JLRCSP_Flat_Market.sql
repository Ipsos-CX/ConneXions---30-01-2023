CREATE NONCLUSTERED INDEX [IX_DEALERS_JLRCSP_Flat_Market]
	ON [DealerManagement].[DEALERS_JLRCSP_Flat] ([Market])
	INCLUDE ([BusinessRegion])