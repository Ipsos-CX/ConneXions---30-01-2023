﻿CREATE NONCLUSTERED INDEX [IX_ROADSIDE_ACCT_MKT_PERM_ITEM_COMMCHANNEL]
	ON [CRM].[ROADSIDE_ACCT_MKT_PERM_ITEM] ([COMMCHANNEL])
	INCLUDE ([AuditID],[ACCT_MKT_PERM_Id],[CONSENT])