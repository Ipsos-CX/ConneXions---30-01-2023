﻿CREATE NONCLUSTERED INDEX [IX_CQI_ACCT_MKT_PERM_ITEM_COMMCHANNEL]
	ON [CRM].[CQI_ACCT_MKT_PERM_ITEM] ([COMMCHANNEL])
	INCLUDE ([AuditID],[ACCT_MKT_PERM_Id],[CONSENT])