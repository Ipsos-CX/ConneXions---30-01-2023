CREATE NONCLUSTERED INDEX [IX_CaseDetails_PartyID] ON [Meta].[CaseDetails] 
	(
		PartyID ASC
	)
	INCLUDE ( DealerPartyID)