﻿CREATE NONCLUSTERED INDEX [IX_PreOwned_ACCT_MKT_PERM_ITEM_AuditID]
	ON [CRM].[PreOwned_ACCT_MKT_PERM_ITEM] ([AuditID])
	INCLUDE ([ACCT_MKT_PERM_Id],[COMMCHANNEL],[CONSENT])