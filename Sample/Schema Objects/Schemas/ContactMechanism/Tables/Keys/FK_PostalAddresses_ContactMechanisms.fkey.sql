ALTER TABLE [ContactMechanism].[PostalAddresses]
    ADD CONSTRAINT [FK_PostalAddresses_ContactMechanisms] FOREIGN KEY ([ContactMechanismID]) 
    REFERENCES [ContactMechanism].[ContactMechanisms] ([ContactMechanismID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

