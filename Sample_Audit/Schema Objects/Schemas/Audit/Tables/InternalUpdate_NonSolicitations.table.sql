CREATE TABLE [Audit].[InternalUpdate_NonSolicitations](
	[PartyID] [dbo].[PartyID] NOT NULL,
	[ExistsAlready] [bit] NOT NULL,
	[AuditID] [dbo].[AuditID] NOT NULL,
	[AuditItemID] [dbo].[AuditItemID] NOT NULL,
	[PartyValid] [bit] NOT NULL,
	[ParentAuditItemID] [dbo].[AuditItemID] NULL,
	[DateProcessed] [datetime2](7) NOT NULL)
