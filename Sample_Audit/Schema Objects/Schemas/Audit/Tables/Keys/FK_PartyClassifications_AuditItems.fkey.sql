ALTER TABLE [Audit].[PartyClassifications]
    ADD CONSTRAINT [FK_PartyClassifications_AuditItems] FOREIGN KEY ([AuditItemID]) 
    REFERENCES [dbo].[AuditItems] ([AuditItemID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

