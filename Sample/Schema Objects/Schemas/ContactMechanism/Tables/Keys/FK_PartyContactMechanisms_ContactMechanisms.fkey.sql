ALTER TABLE [ContactMechanism].[PartyContactMechanisms]
    ADD CONSTRAINT [FK_PartyContactMechanisms_ContactMechanisms] FOREIGN KEY ([ContactMechanismID]) 
    REFERENCES [ContactMechanism].[ContactMechanisms] ([ContactMechanismID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

