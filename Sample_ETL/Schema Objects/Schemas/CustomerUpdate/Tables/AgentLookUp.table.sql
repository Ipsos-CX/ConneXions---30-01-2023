CREATE TABLE [CustomerUpdate].[CRCAgentLookUp]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Code] [dbo].[NameDetail] NOT NULL,
	[FullName] [dbo].[NameDetail]  NULL,
	[FirstName] [dbo].[NameDetail]NOT NULL,
	[Brand] [dbo].[OrganisationName] NOT NULL,
	[MarketCode] [dbo].[Market] NOT NULL,
	[AuditID] [dbo].[AuditID] NULL,
	[AuditItemID] [dbo].[AuditItemID] NULL,
	[ParentAuditItemID] [dbo].[AuditItemID] NULL
)
