CREATE NONCLUSTERED INDEX [IX_PreOwned_ACCT_MKT_PERM_ITEM_AuditID_ACCT_MKT_PERM_Id]
	ON [CRM].[PreOwned_ACCT_MKT_PERM_ITEM] ([AuditID],[ACCT_MKT_PERM_Id])
	INCLUDE ([COMMCHANNEL],[CONSENT])