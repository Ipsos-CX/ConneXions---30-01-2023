CREATE TABLE [Audit].[RejectedCRCCases](
	[AuditID] [dbo].[AuditID] NOT NULL,
	[AuditItemID] [dbo].[AuditItemID] NOT NULL,
	[PartyID] [dbo].[PartyID] NULL,
	[CaseID] [dbo].[CaseID] NULL,
	[Surname] [dbo].[NameDetail] NULL,
	[CoName] [dbo].[NameDetail] NULL,
	[Brand] [varchar](100) NULL,
	[Market] [dbo].[Country] NULL,
	[AgentCode] [dbo].[NameDetail] NULL,
	[ReportDate] [datetime2](7) NULL
)