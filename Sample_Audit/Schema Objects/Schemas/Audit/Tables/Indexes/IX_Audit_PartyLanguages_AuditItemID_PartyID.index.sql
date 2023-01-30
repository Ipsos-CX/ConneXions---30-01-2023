CREATE NONCLUSTERED INDEX [IX_Audit_PartyLanguages_AuditItemID_PartyID] 
	ON [Audit].[PartyLanguages] ([AuditItemID], [PartyID])
