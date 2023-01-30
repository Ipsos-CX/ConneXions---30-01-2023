ALTER TABLE [Party].[ContactPreferences]
    ADD CONSTRAINT [FK_ContactPreferences_Party] FOREIGN KEY ([PartyID]) REFERENCES [Party].[Parties] ([PartyID]) ON DELETE NO ACTION ON UPDATE NO ACTION;
