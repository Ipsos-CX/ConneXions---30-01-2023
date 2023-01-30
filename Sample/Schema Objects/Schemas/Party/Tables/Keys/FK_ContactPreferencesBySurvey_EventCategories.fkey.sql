ALTER TABLE [Party].[ContactPreferencesBySurvey]
    ADD CONSTRAINT [FK_ContactPreferencesBySurvey_EventCategories] FOREIGN KEY ([EventCategoryID]) REFERENCES [Event].[EventCategories] ([EventCategoryID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

