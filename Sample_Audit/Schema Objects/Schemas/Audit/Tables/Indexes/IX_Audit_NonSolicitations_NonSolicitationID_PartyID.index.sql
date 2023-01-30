CREATE NONCLUSTERED INDEX [IX_Audit_NonSolicitations_NonSolicitationID_PartyID] 
	ON [Audit].[NonSolicitations] ([NonSolicitationID], [PartyID]) 
	INCLUDE ([AuditItemID])
