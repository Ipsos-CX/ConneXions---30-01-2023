ALTER TABLE [Audit].[CustomerUpdate_CRCAgentsGlobalList]
	ADD CONSTRAINT [FK_CustomerUpdate_CRCAgentsGlobalList_AuditItems]
	FOREIGN KEY ([AuditItemID])
	REFERENCES [dbo].[AuditItems] ([AuditItemID])
