ALTER TABLE [Party].[PartyLanguages]
    ADD CONSTRAINT [FK_PartyLanguages_Parties] FOREIGN KEY ([PartyID]) 
    REFERENCES [Party].[Parties] ([PartyID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

