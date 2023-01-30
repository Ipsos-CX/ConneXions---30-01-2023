ALTER TABLE [Audit].[CustomerUpdate_Dealer]
	ADD CONSTRAINT [FK_CustomerUpdate_Dealer_AuditItems] 
	FOREIGN KEY (AuditItemID)
	REFERENCES dbo.AuditItems (AuditItemID)	
