ALTER TABLE [Party].[PartyClassifications]
    ADD CONSTRAINT [FK_PartyClassifications_Parties] FOREIGN KEY ([PartyID]) 
    REFERENCES [Party].[Parties] ([PartyID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

