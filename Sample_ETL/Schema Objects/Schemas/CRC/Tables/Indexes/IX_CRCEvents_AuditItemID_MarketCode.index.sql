CREATE NONCLUSTERED INDEX [IX_CRCEvents_AuditItemID_MarketCode] 
	ON [CRC].[CRCEvents] ([AuditItemID]) 
	INCLUDE ([MarketCode], [BrandCode], [Owner], [ClosedBy])
