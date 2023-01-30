ALTER TABLE [Audit].[EmployeeRelationships]
    ADD CONSTRAINT [FK_EmployeeRelationships_AuditItems] FOREIGN KEY ([AuditItemID]) 
    REFERENCES [dbo].[AuditItems] ([AuditItemID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION NOT FOR REPLICATION;

