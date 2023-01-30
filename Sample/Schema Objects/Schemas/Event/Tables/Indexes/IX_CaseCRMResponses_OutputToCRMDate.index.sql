CREATE NONCLUSTERED INDEX [IX_CaseCRMResponses_OutputToCRMDate] 
	ON [Event].[CaseCRMResponses] ([OutputToCRMDate]) 
	INCLUDE ([CaseID])
