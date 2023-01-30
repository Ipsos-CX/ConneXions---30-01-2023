CREATE NONCLUSTERED INDEX [IX_CaseDetails_EventID] 
	ON [Meta].[CaseDetails] ([EventID]) 
	INCLUDE ([CaseID])
