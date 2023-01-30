ALTER TABLE [ContactMechanism].[BlacklistContactMechanisms]
    ADD CONSTRAINT [FK_BlacklistContactMechanisms_ContactMechanisms] FOREIGN KEY ([ContactMechanismID]) 
    REFERENCES [ContactMechanism].[ContactMechanisms] ([ContactMechanismID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

