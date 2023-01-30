ALTER TABLE [OWAP].[Actions]
	ADD CONSTRAINT [FK_Actions_AuditItems] 
	FOREIGN KEY (AuditItemID)
	REFERENCES dbo.AuditItems (AuditItemID)	

