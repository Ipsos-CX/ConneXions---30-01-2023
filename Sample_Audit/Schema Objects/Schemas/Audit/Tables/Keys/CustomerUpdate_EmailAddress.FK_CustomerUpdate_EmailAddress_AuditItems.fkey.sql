ALTER TABLE [Audit].[CustomerUpdate_EmailAddress]
	ADD CONSTRAINT [FK_CustomerUpdate_EmailAddress_AuditItems] 
	FOREIGN KEY (AuditItemID)
	REFERENCES dbo.AuditItems (AuditItemID)	

