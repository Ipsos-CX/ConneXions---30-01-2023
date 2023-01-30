ALTER TABLE [Audit].[CaseRejections]
	ADD CONSTRAINT [FK_CaseRejections_AuditItems] 
	FOREIGN KEY (AuditItemID)
	REFERENCES dbo.AuditItems (AuditItemID)	

