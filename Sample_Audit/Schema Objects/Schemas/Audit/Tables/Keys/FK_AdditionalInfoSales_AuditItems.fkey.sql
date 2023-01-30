ALTER TABLE [Audit].[AdditionalInfoSales]
    ADD CONSTRAINT [FK_AdditionalInfoSales_AuditItems] FOREIGN KEY ([AuditItemID]) 
    REFERENCES [dbo].[AuditItems] ([AuditItemID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

