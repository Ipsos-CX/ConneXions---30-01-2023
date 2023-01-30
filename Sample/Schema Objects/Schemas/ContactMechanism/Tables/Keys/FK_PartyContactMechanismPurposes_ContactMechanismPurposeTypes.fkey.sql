ALTER TABLE [ContactMechanism].[PartyContactMechanismPurposes]
    ADD CONSTRAINT [FK_PartyContactMechanismPurposes_ContactMechanismPurposeTypes] FOREIGN KEY ([ContactMechanismPurposeTypeID]) 
    REFERENCES [ContactMechanism].[ContactMechanismPurposeTypes] ([ContactMechanismPurposeTypeID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

