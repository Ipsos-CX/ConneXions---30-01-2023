CREATE NONCLUSTERED INDEX [IX_Meta_PartyLatestReceivedEmails_PartyID] 
	ON [Meta].[PartyLatestReceivedEmails]
	([PartyID] ASC)