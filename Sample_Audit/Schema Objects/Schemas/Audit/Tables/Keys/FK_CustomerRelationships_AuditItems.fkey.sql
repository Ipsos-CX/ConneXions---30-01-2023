ALTER TABLE [Audit].[CustomerRelationships]
    ADD CONSTRAINT [FK_CustomerRelationships_AuditItems] FOREIGN KEY ([AuditItemID]) 
    REFERENCES [dbo].[AuditItems] ([AuditItemID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

