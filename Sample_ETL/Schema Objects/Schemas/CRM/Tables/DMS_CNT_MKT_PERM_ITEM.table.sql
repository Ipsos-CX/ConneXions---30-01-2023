﻿CREATE TABLE CRM.DMS_CNT_MKT_PERM_ITEM
(
	[ID]						INT IDENTITY(1,1) NOT NULL,
	AuditID						dbo.AuditID NULL,
	VWTID						dbo.VWTID NULL,
	AuditItemID					dbo.AuditItemID NULL,
	Converted_DATEOFCONSENT		DATETIME2(7) NULL,
	CNT_MKT_PERM_Id				INT NULL,
	COMMCHANNEL					NVARCHAR(3) NULL,
	CONSENT						NVARCHAR(3) NULL,
	DATEOFCONSENT				NVARCHAR(10) NULL,
	FORMOFCONSENT				NVARCHAR(3) NULL
)
