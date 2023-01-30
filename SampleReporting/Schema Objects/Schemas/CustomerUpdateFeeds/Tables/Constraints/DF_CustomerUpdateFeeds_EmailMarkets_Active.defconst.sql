ALTER TABLE [CustomerUpdateFeeds].[EmailMarkets]
   ADD CONSTRAINT [DF_CustomerUpdateFeeds_EmailMarkets_Active] 
   DEFAULT 1
   FOR Active
