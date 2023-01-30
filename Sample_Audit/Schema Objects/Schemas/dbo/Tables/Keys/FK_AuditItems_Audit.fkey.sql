ALTER TABLE [dbo].[AuditItems]
    ADD CONSTRAINT [FK_AuditItems_Audit] 
    FOREIGN KEY ([AuditID]) 
    REFERENCES [dbo].[Audit] ([AuditID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

