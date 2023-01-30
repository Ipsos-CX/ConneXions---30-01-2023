CREATE NONCLUSTERED INDEX [IX_EventPartyRoles_RoleTypeID] 
	ON [Event].[EventPartyRoles] ([RoleTypeID]) 
	INCLUDE ([PartyID], [EventID])
