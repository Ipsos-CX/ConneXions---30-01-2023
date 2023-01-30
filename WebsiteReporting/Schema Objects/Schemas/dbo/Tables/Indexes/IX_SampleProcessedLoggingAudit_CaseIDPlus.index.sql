CREATE INDEX [IX_SampleProcessedLoggingAudit_CaseIDPlus]
    ON [dbo].[SampleProcessedLoggingAudit]
	(CaseID, SelectionPoint)
	INCLUDE(AuditID, AuditItemID, AuditTimestamp)


