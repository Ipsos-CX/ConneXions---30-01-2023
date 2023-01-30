ALTER TABLE [SelectionOutput].[OnlineOutput]
    ADD CONSTRAINT [DF_OnlineOutput_EmailCompanyDetails] DEFAULT ('') FOR [EmailCompanyDetails];

