ALTER TABLE [Audit].[PartySalutations]
	ADD CONSTRAINT [FK_PartySalutations_AuditItems] 
	FOREIGN KEY (AuditItemID)
	REFERENCES dbo.AuditItems (AuditItemID)	
