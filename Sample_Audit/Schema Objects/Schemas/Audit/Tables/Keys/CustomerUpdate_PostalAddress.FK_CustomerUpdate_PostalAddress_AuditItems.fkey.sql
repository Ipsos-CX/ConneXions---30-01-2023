ALTER TABLE [Audit].[CustomerUpdate_PostalAddress]
	ADD CONSTRAINT [FK_CustomerUpdate_PostalAddress_AuditItems] 
	FOREIGN KEY (AuditItemID)
	REFERENCES dbo.AuditItems (AuditItemID)	

