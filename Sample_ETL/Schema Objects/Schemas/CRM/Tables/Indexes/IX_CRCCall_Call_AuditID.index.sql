CREATE NONCLUSTERED INDEX [IX_CRCCall_Call_AuditID] 
	ON [CRM].[CRCCall_Call] ([AuditID])
	INCLUDE ([ID],[AuditItemID],[item_Id])
