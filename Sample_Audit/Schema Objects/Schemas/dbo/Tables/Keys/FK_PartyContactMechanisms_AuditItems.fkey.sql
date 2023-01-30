ALTER TABLE [Audit].[PartyContactMechanisms]
    ADD CONSTRAINT [FK_PartyContactMechanisms_AuditItems] FOREIGN KEY ([AuditItemID]) 
    REFERENCES [dbo].[AuditItems] ([AuditItemID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

