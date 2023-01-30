ALTER TABLE [ContactMechanism].[PartyContactMechanisms]
    ADD CONSTRAINT [FK_PartyContactMechanisms_Parties] FOREIGN KEY ([PartyID]) 
    REFERENCES [Party].[Parties] ([PartyID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

