ALTER TABLE [Audit].[SelectionRequirements]
	ADD CONSTRAINT [FK_SelectionRequirements_AuditItems] 
	FOREIGN KEY (AuditItemID)
	REFERENCES dbo.AuditItems (AuditItemID)	

