ALTER TABLE [Party].[ContactPreferencesEventCategoryOverides]
    ADD CONSTRAINT [FK_ContactPreferencesEventCategoryOverides_EventCategories] 
    FOREIGN KEY ([EventCategoryID]) 
    REFERENCES [Event].[EventCategories] ([EventCategoryID]);

