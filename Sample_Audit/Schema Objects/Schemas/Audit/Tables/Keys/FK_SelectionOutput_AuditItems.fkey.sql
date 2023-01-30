ALTER TABLE [Audit].[SelectionOutput]
    ADD CONSTRAINT [FK_SelectionOutput_AuditItems] FOREIGN KEY ([AuditItemID]) 
    REFERENCES [dbo].[AuditItems] ([AuditItemID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

