ALTER TABLE [dbo].[Markets]
    ADD CONSTRAINT [DF_Markets_EventXDealerList] DEFAULT 1 FOR EventXDealerList;

