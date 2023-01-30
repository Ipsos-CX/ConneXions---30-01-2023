CREATE NONCLUSTERED INDEX [IX_CaseResponseStatuses_ResponseStatusID]
	ON [CRM].[CaseResponseStatuses] ([ResponseStatusID])
	INCLUDE ([CaseID],[EventID],[LoadedToConnexions])
