CREATE NONCLUSTERED INDEX [IX_Audit_PartyRoles_AuditItemID_PartyRoleID] 
	ON [Audit].[PartyRoles] ([AuditItemID], [PartyRoleID])
