﻿CREATE TABLE CRM.PreOwned_ACCT_MKT_PERM
(
	[ID]					INT IDENTITY(1,1) NOT NULL,
	AuditID	dbo.AuditID		NULL,
	VWTID	dbo.VWTID		NULL,
	AuditItemID				dbo.AuditItemID NULL,
	item_Id					INT NULL,
	ACCT_MKT_PERM_Id		INT NULL
)
