CREATE NONCLUSTERED INDEX [IX_DMS_CNT_MKT_PERM_ITEM_AuditID__CNT_MKT_PERM_Id]
	ON [CRM].[DMS_CNT_MKT_PERM_ITEM] ([AuditID],[CNT_MKT_PERM_Id])
	INCLUDE ([COMMCHANNEL],[CONSENT])