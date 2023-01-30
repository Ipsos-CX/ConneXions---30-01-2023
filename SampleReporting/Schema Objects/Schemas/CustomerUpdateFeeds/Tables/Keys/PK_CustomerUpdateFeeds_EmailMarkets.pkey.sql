ALTER TABLE [CustomerUpdateFeeds].[EmailMarkets]
    ADD CONSTRAINT [PK_CustomerUpdateFeeds_EmailMarkets] 
    PRIMARY KEY CLUSTERED 
    ([Market] ASC, [DealerCode] ASC)