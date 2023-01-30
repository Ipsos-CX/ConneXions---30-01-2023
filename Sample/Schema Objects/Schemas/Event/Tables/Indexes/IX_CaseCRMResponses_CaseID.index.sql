CREATE NONCLUSTERED INDEX [IX_CaseCRMResponses_CaseID] 
	ON [Event].[CaseCRMResponses] ([CaseID]) 
	INCLUDE ([QuestionNumber], [QuestionText], [Response])
