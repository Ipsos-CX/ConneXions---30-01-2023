CREATE TABLE [SampleReport].[OrphanDealerIDCheck]
(
--BUG 16676
	[ImportedAuditItemID] bigint NOT NULL,
	[IsOrphan] [INT] NULL,
	[AuditID] bigint NOT NULL,
	[AuditItemID] bigint NOT NULL,
	[RunDate]     DATETIME NOT NULL

)
