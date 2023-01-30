CREATE TABLE [InternalUpdate].[NonSolicitations](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[PartyID] [dbo].[PartyID] NOT NULL,
	[ExistsAlready] [bit] NOT NULL,
	[AuditID] [dbo].[AuditID] NULL,
	[AuditItemID] [dbo].[AuditItemID] NULL,
	[PartyValid] [bit] NOT NULL,
	[ParentAuditItemID] [dbo].[AuditItemID] NULL,
	[DateProcessed] [datetime2](7) NULL)