ALTER TABLE [Audit].[CustomerUpdate_RegistrationNumber]
	ADD CONSTRAINT [FK_CustomerUpdate_RegistrationNumber_AuditItems] 
	FOREIGN KEY (AuditItemID)
	REFERENCES dbo.AuditItems (AuditItemID)	
