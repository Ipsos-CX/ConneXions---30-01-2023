ALTER TABLE [Event].[AutomotiveEventBasedInterviews]
    ADD CONSTRAINT [FK_AutomotiveEventBasedInterviews_Cases] FOREIGN KEY ([CaseID]) REFERENCES [Event].[Cases] ([CaseID]) ON DELETE NO ACTION ON UPDATE NO ACTION NOT FOR REPLICATION;

