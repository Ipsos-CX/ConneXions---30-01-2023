CREATE NONCLUSTERED INDEX [IX_AutomotiveEventBasedInterviews_PartyID] 
	ON [Event].[AutomotiveEventBasedInterviews] ([PartyID]) 
	INCLUDE ([CaseID])
