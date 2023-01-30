CREATE NONCLUSTERED INDEX [IX_CQI_AuditID] 
	ON [CRM].[CQI] ([AuditID])
	INCLUDE ([ID],[AuditItemID],[item_Id])
