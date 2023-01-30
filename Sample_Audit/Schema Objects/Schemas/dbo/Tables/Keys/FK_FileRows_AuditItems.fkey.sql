ALTER TABLE [dbo].[FileRows]
    ADD CONSTRAINT [FK_FileRows_AuditItems] FOREIGN KEY ([AuditItemID]) REFERENCES [dbo].[AuditItems] ([AuditItemID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

