ALTER TABLE [Event].[CaseOutput]
    ADD CONSTRAINT [FK_CaseOutput_CaseID] FOREIGN KEY ([CaseID]) 
    REFERENCES [Event].[Cases] ([CaseID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

