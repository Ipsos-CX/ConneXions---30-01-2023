CREATE TABLE [Lookup].[CRCAgents_GlobalList]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AuditItemID] [dbo].[AuditItemID] NULL,
	[CDSID] [dbo].[NameDetail] NOT NULL,
	[FirstName] [dbo].[NameDetail] NOT NULL,
	[Surname] [dbo].[NameDetail] NOT NULL,
	[DisplayOnQuestionnaire] [dbo].[NameDetail] NOT NULL,
	[DisplayOnWebsite] [dbo].[NameDetail] NULL,
	[FullName] [dbo].[NameDetail] NOT NULL,
	[Market] [dbo].[Country] NOT NULL,
	[MarketCode] [varchar](50) NULL
)
