CREATE NONCLUSTERED INDEX [IX_PreOwned_CNT_MKT_PERM_ITEM_AuditID]
	ON [CRM].[PreOwned_CNT_MKT_PERM_ITEM] ([AuditID])
	INCLUDE ([CNT_MKT_PERM_Id],[COMMCHANNEL],[CONSENT])