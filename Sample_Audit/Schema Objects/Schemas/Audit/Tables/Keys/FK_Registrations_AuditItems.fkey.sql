ALTER TABLE [Audit].[Registrations]
	ADD CONSTRAINT [FK_Registrations_AuditItems] 
	FOREIGN KEY (AuditItemID)
	REFERENCES dbo.AuditItems (AuditItemID)	

