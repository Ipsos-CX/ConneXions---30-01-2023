ALTER TABLE [ContactMechanism].[PartyContactMechanismPurposes]
    ADD CONSTRAINT [FK_PartyContactMechanismPurposes_PartyContactMechanisms] FOREIGN KEY ([ContactMechanismID], [PartyID]) 
    REFERENCES [ContactMechanism].[PartyContactMechanisms] ([ContactMechanismID], [PartyID]) 
    ON DELETE CASCADE ON UPDATE NO ACTION;

