ALTER TABLE [Event].[CaseContactMechanismOutcomes]
    ADD CONSTRAINT [FK_CaseContactMechanismOutcomes_OutcomeCodes] FOREIGN KEY ([OutcomeCode], [OutcomeCodeTypeID]) 
    REFERENCES [ContactMechanism].[OutcomeCodes] ([OutcomeCode], [OutcomeCodeTypeID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

