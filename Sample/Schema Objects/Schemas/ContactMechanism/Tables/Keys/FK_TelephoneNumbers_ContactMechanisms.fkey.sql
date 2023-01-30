ALTER TABLE [ContactMechanism].[TelephoneNumbers]
    ADD CONSTRAINT [FK_TelephoneNumbers_ContactMechanisms] FOREIGN KEY ([ContactMechanismID]) 
    REFERENCES [ContactMechanism].[ContactMechanisms] ([ContactMechanismID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

