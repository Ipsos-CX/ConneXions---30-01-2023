ALTER TABLE [ContactMechanism].[ContactMechanisms]
    ADD CONSTRAINT [FK_ContactMechanisms_ContactMechanismTypes] FOREIGN KEY ([ContactMechanismTypeID]) 
    REFERENCES [ContactMechanism].[ContactMechanismTypes] ([ContactMechanismTypeID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

