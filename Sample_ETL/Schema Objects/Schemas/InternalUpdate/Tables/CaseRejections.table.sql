CREATE TABLE [InternalUpdate].[CaseRejections](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[PartyID] [dbo].[PartyID] NOT NULL,
	[CaseID] [dbo].[CaseID] NOT NULL,
	[Rejection] [bit] NOT NULL,
	[Required] [bit] NOT NULL,
	[AuditID] [dbo].[AuditID] NULL,
	[AuditItemID] [dbo].[AuditItemID] NULL,
	[CasePartyCombinationValid] [bit] NOT NULL,
	[ParentAuditItemID] [dbo].[AuditItemID] NULL,
	[DateProcessed] DATETIME2 NULL
);