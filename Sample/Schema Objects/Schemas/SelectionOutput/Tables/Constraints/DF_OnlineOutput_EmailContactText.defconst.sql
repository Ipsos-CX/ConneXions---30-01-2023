ALTER TABLE [SelectionOutput].[OnlineOutput]
    ADD CONSTRAINT [DF_OnlineOutput_EmailContactText] DEFAULT ('') FOR [EmailContactText];

