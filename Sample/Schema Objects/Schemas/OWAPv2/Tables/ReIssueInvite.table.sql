CREATE TABLE [OWAPv2].[ReIssueInvite] (
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[PartyID] [dbo].[PartyID] NOT NULL,
	[CaseID] [dbo].[CaseID] NOT NULL,
	[ReIssue] BIT NULL,
	[AuditID] [dbo].[AuditID] NULL,
	[AuditItemID] [dbo].[AuditItemID] NULL,
	[CasePartyCombinationValid] [bit] NULL,
	[DateProcessed] [datetime2](7) NULL,
) 
