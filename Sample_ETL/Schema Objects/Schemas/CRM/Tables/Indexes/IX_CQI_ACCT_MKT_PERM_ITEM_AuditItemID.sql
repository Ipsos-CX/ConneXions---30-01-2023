﻿CREATE NONCLUSTERED INDEX [IX_CQI_ACCT_MKT_PERM_ITEM_AuditItemID]
	ON [CRM].[CQI_ACCT_MKT_PERM_ITEM] ([AuditItemID])
	INCLUDE ([AuditID],[ACCT_MKT_PERM_Id])