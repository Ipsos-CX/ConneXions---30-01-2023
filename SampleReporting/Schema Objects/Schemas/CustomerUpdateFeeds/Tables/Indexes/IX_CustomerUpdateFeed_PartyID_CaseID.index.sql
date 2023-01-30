CREATE NONCLUSTERED INDEX [IX_CustomerUpdateFeed_PartyID_CaseID]
    ON [CustomerUpdateFeeds].[CustomerUpdateFeed]([PartyID] ASC, [CaseID] ASC) ;


