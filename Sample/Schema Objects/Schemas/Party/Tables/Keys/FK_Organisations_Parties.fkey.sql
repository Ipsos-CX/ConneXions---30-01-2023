ALTER TABLE [Party].[Organisations]
    ADD CONSTRAINT [FK_Organisations_Parties] FOREIGN KEY ([PartyID]) REFERENCES [Party].[Parties] ([PartyID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

