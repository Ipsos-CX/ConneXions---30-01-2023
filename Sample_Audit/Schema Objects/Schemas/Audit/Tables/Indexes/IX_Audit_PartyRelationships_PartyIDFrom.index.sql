CREATE NONCLUSTERED INDEX [IX_Audit_PartyRelationships_PartyIDFrom] 
	ON [Audit].[PartyRelationships] ([PartyIDFrom]) 
	INCLUDE ([AuditItemID], [PartyIDTo], [RoleTypeIDFrom], [RoleTypeIDTo])
