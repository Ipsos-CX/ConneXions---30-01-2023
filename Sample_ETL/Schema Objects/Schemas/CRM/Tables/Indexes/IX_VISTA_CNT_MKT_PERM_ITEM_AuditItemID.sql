CREATE NONCLUSTERED INDEX [IX_VISTA_CNT_MKT_PERM_ITEM_AuditItemID]
	ON [CRM].[VISTA_CNT_MKT_PERM_ITEM] ([AuditItemID])
	INCLUDE ([AuditID],[CNT_MKT_PERM_Id])
