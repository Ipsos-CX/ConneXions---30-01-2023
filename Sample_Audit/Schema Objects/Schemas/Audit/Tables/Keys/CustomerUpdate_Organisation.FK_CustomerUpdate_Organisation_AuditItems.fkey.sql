ALTER TABLE [Audit].[CustomerUpdate_Organisation]
	ADD CONSTRAINT [FK_CustomerUpdate_Organisation_AuditItems] 
	FOREIGN KEY (AuditItemID)
	REFERENCES dbo.AuditItems (AuditItemID)	
