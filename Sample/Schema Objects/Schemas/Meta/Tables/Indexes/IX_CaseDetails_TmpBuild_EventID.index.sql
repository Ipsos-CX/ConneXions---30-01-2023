CREATE NONCLUSTERED INDEX [IX_CaseDetails_TmpBuild_EventID] 
	ON [Meta].[CaseDetails_TmpBuild] ([EventID]) 
	INCLUDE ([CaseID])
