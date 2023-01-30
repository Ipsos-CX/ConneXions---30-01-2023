CREATE INDEX [IX_PreOwned_AuditID]
	ON [CRM].[PreOwned] ([AuditID])
	INCLUDE ([ID],[AuditItemID],[item_Id])