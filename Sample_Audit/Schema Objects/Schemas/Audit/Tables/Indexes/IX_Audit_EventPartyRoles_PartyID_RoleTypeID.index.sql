CREATE NONCLUSTERED INDEX [IX_Audit_EventPartyRoles_PartyID_RoleTypeID] 
	ON [Audit].[EventPartyRoles] ([PartyID], [RoleTypeID]) 
	INCLUDE ([AuditItemID], [EventID], [DealerCode], [DealerCodeOriginatorPartyID])
