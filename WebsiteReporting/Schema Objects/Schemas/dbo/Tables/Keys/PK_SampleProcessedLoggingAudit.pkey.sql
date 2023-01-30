ALTER TABLE [dbo].[SampleProcessedLoggingAudit]
	ADD CONSTRAINT [PK_SampleProcessedLoggingAudit]
	PRIMARY KEY (AuditItemID, AuditID, AuditTimestamp)