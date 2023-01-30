ALTER TABLE [Party].[LegalOrganisations]
    ADD CONSTRAINT [FK_LegalOrganisation_Organisations] FOREIGN KEY ([PartyID]) REFERENCES [Party].[Organisations] ([PartyID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

