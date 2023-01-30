ALTER TABLE [Event].[Cases]
    ADD CONSTRAINT [FK_Cases_CaseStatusTypes] FOREIGN KEY ([CaseStatusTypeID]) REFERENCES [Event].[CaseStatusTypes] ([CaseStatusTypeID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

