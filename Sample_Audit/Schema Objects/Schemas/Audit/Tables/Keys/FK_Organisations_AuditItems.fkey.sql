ALTER TABLE [Audit].[Organisations]
    ADD CONSTRAINT [FK_Organisations_AuditItems] FOREIGN KEY ([AuditItemID]) 
    REFERENCES [dbo].[AuditItems] ([AuditItemID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

