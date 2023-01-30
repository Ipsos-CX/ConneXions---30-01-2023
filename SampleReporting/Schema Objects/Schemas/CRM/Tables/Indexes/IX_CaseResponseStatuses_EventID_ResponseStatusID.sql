CREATE NONCLUSTERED INDEX [IX_CaseResponseStatuses_EventID_ResponseStatusID]
	ON [CRM].[CaseResponseStatuses] ([EventID],[ResponseStatusID])