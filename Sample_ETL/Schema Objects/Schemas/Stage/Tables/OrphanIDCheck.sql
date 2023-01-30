CREATE TABLE [Stage].[OrphanIDCheck]
--BUG 16676
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ImportedAuditItemID] [dbo].[AuditItemID] NOT NULL,
	[IsOrphan] [INT] NULL,
	[AuditID] [dbo].[AuditID] NULL,
	[AuditItemID] [dbo].[AuditItemID] NULL
)
