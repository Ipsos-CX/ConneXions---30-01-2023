CREATE NONCLUSTERED INDEX [IX_CRCEvents_AuditItemID_CaseNumber]
ON [CRC].[CRCEvents] ([AuditItemID])
	INCLUDE ([CaseNumber])
GO
