ALTER TABLE [Audit].[Titles]
	ADD CONSTRAINT [FK_Titles_AuditItems] 
	FOREIGN KEY (AuditItemID)
	REFERENCES dbo.AuditItems (AuditItemID)	

