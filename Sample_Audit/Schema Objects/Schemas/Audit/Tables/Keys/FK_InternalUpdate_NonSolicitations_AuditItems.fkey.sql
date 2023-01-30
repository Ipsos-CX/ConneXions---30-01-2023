ALTER TABLE [Audit].[InternalUpdate_NonSolicitations]
	ADD CONSTRAINT [FK_InternalUpdate_NonSolicitations_AuditItems] 
	FOREIGN KEY ([AuditItemID])
	REFERENCES [dbo].[AuditItems] ([AuditItemID])

