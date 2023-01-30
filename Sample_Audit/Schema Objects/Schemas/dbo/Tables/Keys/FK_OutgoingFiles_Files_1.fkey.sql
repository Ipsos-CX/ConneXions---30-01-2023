ALTER TABLE [dbo].[OutgoingFiles]
    ADD CONSTRAINT [FK_OutgoingFiles_Files] FOREIGN KEY ([AuditID]) REFERENCES [dbo].[Files] ([AuditID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

