CREATE TABLE [Audit].[CustomerUpdate_CRCAgentsGlobalList](
	[AuditID] [dbo].[AuditID] NULL,
	[AuditItemID] [dbo].[AuditItemID] NULL,
	[ParentAuditItemID] [dbo].[AuditItemID] NOT NULL,
	[CDSID] [dbo].[NameDetail] NOT NULL,
	[FirstName] [dbo].[NameDetail] NOT NULL,
	[Surname] [dbo].[NameDetail] NOT NULL,
	[DisplayOnQuestionnaire] [dbo].[NameDetail] NOT NULL,
	[DisplayOnWebsite] [dbo].[NameDetail] NULL,
	[FullName] [dbo].[NameDetail] NOT NULL,
	[Market] [dbo].[Country] NOT NULL,
	[MarketCode] [varchar](50) NULL,
	[DateProcessed] [datetime2](7) NULL
)
