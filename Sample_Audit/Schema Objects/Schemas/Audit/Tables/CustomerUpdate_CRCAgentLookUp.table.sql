CREATE TABLE [Audit].[CustomerUpdate_CRCAgentLookUp](
	[AuditItemID] [dbo].[AuditItemID] NOT NULL,
	[Code] [dbo].[NameDetail] NOT NULL,
	[FullName] [dbo].[NameDetail] NULL,
	[FirstName] [dbo].[NameDetail] NOT NULL,
	[Brand] [dbo].[OrganisationName] NOT NULL,
	[MarketCode] NVARCHAR(255) NOT NULL
) 