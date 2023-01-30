ALTER TABLE [Audit].[CustomerUpdate_ContactOutcome]
	ADD CONSTRAINT [FK_CustomerUpdate_ContactOutcome_AuditItems] 
	FOREIGN KEY (AuditItemID)
	REFERENCES dbo.AuditItems (AuditItemID)	
