ALTER TABLE [Party].[ContactPreferencesEventCategoryOverides]
    ADD CONSTRAINT [FK_ContactPreferencesEventCategoryOverides_Markets] 
    FOREIGN KEY ([MarketID]) 
    REFERENCES [dbo].[Markets] ([MarketID]);

