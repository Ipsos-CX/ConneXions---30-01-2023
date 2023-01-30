ALTER TABLE [dbo].[IncomingFiles]
    ADD CONSTRAINT [FK_IncomingFiles_Files] FOREIGN KEY ([AuditID]) REFERENCES [dbo].[Files] ([AuditID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

