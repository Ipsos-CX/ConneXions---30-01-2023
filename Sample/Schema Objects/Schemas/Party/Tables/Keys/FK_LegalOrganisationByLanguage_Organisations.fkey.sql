ALTER TABLE [Party].[LegalOrganisationsByLanguage]
    ADD CONSTRAINT [FK_LegalOrganisationByLanguage_Organisations] FOREIGN KEY ([PartyID]) REFERENCES [Party].[Organisations] ([PartyID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

