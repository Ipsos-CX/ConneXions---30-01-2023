ALTER TABLE [ContactMechanism].[ContactMechanismTypePurposes]
    ADD CONSTRAINT [FK_ContactMechanismTypePurposes_ContactMechanismTypes] FOREIGN KEY ([ContactMechanismTypeID]) 
    REFERENCES [ContactMechanism].[ContactMechanismTypes] ([ContactMechanismTypeID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

