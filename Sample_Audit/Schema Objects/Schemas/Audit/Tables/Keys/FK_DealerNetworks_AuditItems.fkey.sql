ALTER TABLE [Audit].[DealerNetworks]
    ADD CONSTRAINT [FK_DealerNetworks_AuditItems] FOREIGN KEY ([AuditItemID]) REFERENCES [dbo].[AuditItems] ([AuditItemID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

