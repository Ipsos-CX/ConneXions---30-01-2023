CREATE TABLE [CRM].[LandRover_Experience_ACCT_MKT_PERM_ITEM](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AuditID] [dbo].[AuditID] NULL,
	[VWTID] [dbo].[VWTID] NULL,
	[AuditItemID] [dbo].[AuditItemID] NULL,
	[Converted_DATEOFCONSENT] [datetime2](7) NULL,
	[ACCT_MKT_PERM_Id] [int] NULL,
	[COMMCHANNEL] [nvarchar](3) NULL,
	[CONSENT] [nvarchar](3) NULL,
	[DATEOFCONSENT] [nvarchar](10) NULL,
	[FORMOFCONSENT] [nvarchar](3) NULL
) 