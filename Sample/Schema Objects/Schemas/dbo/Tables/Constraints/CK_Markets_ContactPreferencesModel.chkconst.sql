ALTER TABLE [dbo].[Markets]
    ADD CONSTRAINT [CK_Markets_ContactPreferencesModel] 
    CHECK ([ContactPreferencesModel]='By Survey' OR [ContactPreferencesModel]='Global');
