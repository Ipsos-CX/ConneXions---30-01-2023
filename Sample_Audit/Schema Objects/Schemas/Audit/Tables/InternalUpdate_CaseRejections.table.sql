CREATE TABLE [Audit].[InternalUpdate_CaseRejections](
	[PartyID] [dbo].[PartyID] NOT NULL,
	[CaseID] [dbo].[CaseID] NOT NULL,
	[Rejection] [bit] NOT NULL,
	[Required] [bit] NOT NULL,
	[AuditID] [dbo].[AuditID] NOT NULL,
	[AuditItemID] [dbo].[AuditItemID] NOT NULL,
	[CasePartyCombinationValid] [bit] NOT NULL,
	[ParentAuditItemID] [dbo].[AuditItemID] NULL,
	[DateProcessed] DATETIME2 NOT NULL
)