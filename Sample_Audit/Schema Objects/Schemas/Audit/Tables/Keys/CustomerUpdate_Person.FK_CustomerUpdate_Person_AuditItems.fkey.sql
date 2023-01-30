ALTER TABLE [Audit].[CustomerUpdate_Person]
	ADD CONSTRAINT [FK_CustomerUpdate_Person_AuditItems] 
	FOREIGN KEY (AuditItemID)
	REFERENCES dbo.AuditItems (AuditItemID)	
