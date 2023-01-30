ALTER TABLE [ContactMechanism].[ContactMechanismTypePurposes]
    ADD CONSTRAINT [FK_ContactMechanismTypePurposes_ContactMechanismPurposeTypes] FOREIGN KEY ([ContactMechanismPurposeTypeID]) 
    REFERENCES [ContactMechanism].[ContactMechanismPurposeTypes] ([ContactMechanismPurposeTypeID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

