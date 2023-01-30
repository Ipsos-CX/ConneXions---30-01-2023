CREATE NONCLUSTERED INDEX [IX_GeneralEnquiryEvents_AuditItemID_MarketCode] 
	ON [GeneralEnquiry].[GeneralEnquiryEvents] ([AuditItemID]) 
	INCLUDE ([MarketCode], [BrandCode], [Owner], [ClosedBy])
