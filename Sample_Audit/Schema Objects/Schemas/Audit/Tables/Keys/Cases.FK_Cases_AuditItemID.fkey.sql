ALTER TABLE [Audit].[Cases]
	ADD CONSTRAINT [FK_Cases_AuditItemID] 
	FOREIGN KEY (AuditItemID)
	REFERENCES dbo.AuditItems (AuditItemID)	

