ALTER TABLE [Audit].[TitleVariations]
	ADD CONSTRAINT [FK_TitleVariations_AuditItemID] 
	FOREIGN KEY (AuditItemID)
	REFERENCES dbo.AuditItems (AuditItemID)	

