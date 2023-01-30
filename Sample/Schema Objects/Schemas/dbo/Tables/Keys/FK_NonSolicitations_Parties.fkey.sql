ALTER TABLE [dbo].[NonSolicitations]
    ADD CONSTRAINT [FK_NonSolicitations_Parties] FOREIGN KEY ([PartyID]) 
    REFERENCES [Party].[Parties] ([PartyID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

