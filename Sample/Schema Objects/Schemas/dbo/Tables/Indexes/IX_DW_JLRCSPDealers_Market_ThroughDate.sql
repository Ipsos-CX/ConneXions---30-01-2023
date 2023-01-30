CREATE NONCLUSTERED INDEX [IX_DW_JLRCSPDealers_Market_ThroughDate]
	ON [dbo].[DW_JLRCSPDealers] ([Market],[ThroughDate])
	INCLUDE ([BusinessRegion])