ALTER TABLE [Party].[ContactPreferences]
    ADD CONSTRAINT [DF_ContactPreferences_UpdateDate] DEFAULT GETDATE() FOR [UpdateDate];

