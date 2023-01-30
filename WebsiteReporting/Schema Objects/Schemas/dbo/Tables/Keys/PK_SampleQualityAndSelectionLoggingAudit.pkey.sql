ALTER TABLE [dbo].[SampleQualityAndSelectionLoggingAudit]
	ADD CONSTRAINT [PK_SampleQualityAndSelectionLoggingAudit]
	PRIMARY KEY (AuditItemID, AuditID, AuditTimestamp)