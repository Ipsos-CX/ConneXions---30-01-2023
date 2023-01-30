ALTER TABLE [ContactMechanism].[OutcomeCodes]
    ADD CONSTRAINT [FK_OutcomeCodes_OutcomeCodeTypeID] FOREIGN KEY ([OutcomeCodeTypeID]) 
    REFERENCES [ContactMechanism].[OutcomeCodeTypes] ([OutcomeCodeTypeID])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

