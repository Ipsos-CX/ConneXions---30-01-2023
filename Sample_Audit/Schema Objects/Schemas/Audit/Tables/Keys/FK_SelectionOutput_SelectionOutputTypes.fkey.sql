ALTER TABLE [Audit].[SelectionOutput]
    ADD CONSTRAINT [FK_SelectionOutput_SelectionOutputTypes] FOREIGN KEY ([SelectionOutputTypeID]) 
    REFERENCES [dbo].[SelectionOutputTypes] ([SelectionOutputTypeID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

