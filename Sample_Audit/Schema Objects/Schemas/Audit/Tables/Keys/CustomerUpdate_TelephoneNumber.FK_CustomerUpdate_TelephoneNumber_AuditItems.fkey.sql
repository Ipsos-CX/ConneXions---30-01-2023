ALTER TABLE [Audit].[CustomerUpdate_TelephoneNumber]
	ADD CONSTRAINT [FK_CustomerUpdate_TelephoneNumber_AuditItems] 
	FOREIGN KEY (AuditItemID)
	REFERENCES dbo.AuditItems (AuditItemID)	

