ALTER TABLE [Event].[CaseContactMechanismOutcomes]
    ADD CONSTRAINT [FK_CaseContactMechanismOutcomes_ContactMechanisms] FOREIGN KEY ([ContactMechanismID]) 
    REFERENCES [ContactMechanism].[ContactMechanisms] ([ContactMechanismID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

