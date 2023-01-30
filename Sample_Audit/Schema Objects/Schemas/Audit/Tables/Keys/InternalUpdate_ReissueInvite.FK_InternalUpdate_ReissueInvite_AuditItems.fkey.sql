ALTER TABLE [Audit].[InternalUpdate_ReissueInvite]
	ADD CONSTRAINT [FK_InternalUpdate_ReissueInvite_AuditItems] 
	FOREIGN KEY (AuditItemID)
	REFERENCES dbo.AuditItems (AuditItemID)	
