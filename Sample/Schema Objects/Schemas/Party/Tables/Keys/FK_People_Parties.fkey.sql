ALTER TABLE [Party].[People]
    ADD CONSTRAINT [FK_People_Parties] FOREIGN KEY ([PartyID]) 
    REFERENCES [Party].[Parties] ([PartyID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

