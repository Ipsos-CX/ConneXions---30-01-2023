ALTER TABLE [Event].[CaseContactMechanismOutcomes]
    ADD CONSTRAINT [FK_CaseContactMechanismOutcomes_Cases] FOREIGN KEY ([CaseID]) 
    REFERENCES [Event].[Cases] ([CaseID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

