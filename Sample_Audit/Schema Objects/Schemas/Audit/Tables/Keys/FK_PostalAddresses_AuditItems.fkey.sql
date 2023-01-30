ALTER TABLE [Audit].[PostalAddresses]
    ADD CONSTRAINT [FK_PostalAddresses_AuditItems] FOREIGN KEY ([AuditItemID]) 
    REFERENCES [dbo].[AuditItems] ([AuditItemID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

