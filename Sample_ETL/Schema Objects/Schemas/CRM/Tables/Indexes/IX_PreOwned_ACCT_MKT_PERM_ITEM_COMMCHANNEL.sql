﻿CREATE NONCLUSTERED INDEX [IX_PreOwned_ACCT_MKT_PERM_ITEM_COMMCHANNEL]
	ON [CRM].[PreOwned_ACCT_MKT_PERM_ITEM] ([COMMCHANNEL])
	INCLUDE ([AuditID],[ACCT_MKT_PERM_Id],[CONSENT])