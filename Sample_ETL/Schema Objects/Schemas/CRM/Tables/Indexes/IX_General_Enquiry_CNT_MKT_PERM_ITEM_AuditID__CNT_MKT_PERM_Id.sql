﻿CREATE NONCLUSTERED INDEX [IX_General_Enquiry_CNT_MKT_PERM_ITEM_AuditID__CNT_MKT_PERM_Id]
	ON [CRM].[General_Enquiry_CNT_MKT_PERM_ITEM] ([AuditID],[CNT_MKT_PERM_Id])
	INCLUDE ([COMMCHANNEL],[CONSENT])