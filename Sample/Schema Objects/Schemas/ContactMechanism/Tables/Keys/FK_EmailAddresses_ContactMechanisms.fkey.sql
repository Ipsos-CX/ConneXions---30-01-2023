ALTER TABLE [ContactMechanism].[EmailAddresses]
    ADD CONSTRAINT [FK_EmailAddresses_ContactMechanisms] FOREIGN KEY ([ContactMechanismID]) REFERENCES [ContactMechanism].[ContactMechanisms] ([ContactMechanismID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

