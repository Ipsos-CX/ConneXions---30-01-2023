ALTER TABLE [Party].[ContactPreferencesBySurvey]
    ADD CONSTRAINT [FK_ContactPreferencesBySurvey_Party] FOREIGN KEY ([PartyID]) REFERENCES [Party].[Parties] ([PartyID]) ON DELETE NO ACTION ON UPDATE NO ACTION;
