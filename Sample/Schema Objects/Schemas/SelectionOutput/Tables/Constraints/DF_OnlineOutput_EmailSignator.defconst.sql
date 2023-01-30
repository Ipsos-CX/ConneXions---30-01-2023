ALTER TABLE [SelectionOutput].[OnlineOutput]
    ADD CONSTRAINT [DF_OnlineOutput_EmailSignator] DEFAULT ('') FOR [EmailSignator];

