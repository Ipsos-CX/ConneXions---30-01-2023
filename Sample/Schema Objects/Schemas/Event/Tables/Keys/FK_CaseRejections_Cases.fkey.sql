ALTER TABLE [Event].[CaseRejections]
    ADD CONSTRAINT [FK_CaseRejections_Cases] FOREIGN KEY ([CaseID]) REFERENCES [Event].[Cases] ([CaseID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

