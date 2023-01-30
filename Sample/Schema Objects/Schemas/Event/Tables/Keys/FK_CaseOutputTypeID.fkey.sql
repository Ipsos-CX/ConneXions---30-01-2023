ALTER TABLE [Event].[CaseOutput]
    ADD CONSTRAINT [FK_CaseOutput_CaseOutputTypes] FOREIGN KEY ([CaseOutputTypeID]) 
    REFERENCES [Event].[CaseOutputTypes] ([CaseOutputTypeID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

