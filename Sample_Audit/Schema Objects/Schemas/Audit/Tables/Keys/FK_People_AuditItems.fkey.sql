ALTER TABLE [Audit].[People]
    ADD CONSTRAINT [FK_People_AuditItems] FOREIGN KEY ([AuditItemID]) 
    REFERENCES [dbo].[AuditItems] ([AuditItemID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

