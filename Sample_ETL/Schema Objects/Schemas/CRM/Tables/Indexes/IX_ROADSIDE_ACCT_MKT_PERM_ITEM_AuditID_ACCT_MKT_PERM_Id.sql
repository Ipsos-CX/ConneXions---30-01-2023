CREATE NONCLUSTERED INDEX [IX_ROADSIDE_ACCT_MKT_PERM_ITEM_AuditID_ACCT_MKT_PERM_Id]
	ON [CRM].[ROADSIDE_ACCT_MKT_PERM_ITEM] ([AuditID],[ACCT_MKT_PERM_Id])
	INCLUDE ([COMMCHANNEL],[CONSENT])