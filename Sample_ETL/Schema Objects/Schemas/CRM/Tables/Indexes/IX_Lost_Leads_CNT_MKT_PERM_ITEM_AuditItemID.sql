CREATE NONCLUSTERED INDEX [IX_Lost_Leads_CNT_MKT_PERM_ITEM_AuditItemID]
	ON [CRM].[Lost_Leads_CNT_MKT_PERM_ITEM] ([AuditItemID])
	INCLUDE ([AuditID],[CNT_MKT_PERM_Id])