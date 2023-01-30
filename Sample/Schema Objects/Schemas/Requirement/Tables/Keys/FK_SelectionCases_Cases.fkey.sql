ALTER TABLE [Requirement].[SelectionCases]
    ADD CONSTRAINT [FK_SelectionCases_Cases] FOREIGN KEY ([CaseID]) REFERENCES [Event].[Cases] ([CaseID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

