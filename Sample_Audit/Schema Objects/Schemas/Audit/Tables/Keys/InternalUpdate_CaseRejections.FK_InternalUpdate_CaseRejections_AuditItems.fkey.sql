ALTER TABLE [Audit].[InternalUpdate_CaseRejections]
	ADD CONSTRAINT [FK_InternalUpdate_CaseRejections_AuditItems] 
	FOREIGN KEY ([AuditItemID])
	REFERENCES [dbo].[AuditItems] ([AuditItemID])

