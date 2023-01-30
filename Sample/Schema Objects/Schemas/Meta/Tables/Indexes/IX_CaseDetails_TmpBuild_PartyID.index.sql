CREATE NONCLUSTERED INDEX [IX_CaseDetails_TmpBuild_PartyID] ON [Meta].[CaseDetails_TmpBuild] 
	(
		PartyID ASC
	)
	INCLUDE ( DealerPartyID)