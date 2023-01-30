ALTER TABLE [Vehicle].[ModelVariants]
    ADD CONSTRAINT [FK_ModelVariants_ModelID] FOREIGN KEY ([ModelID]) 
    REFERENCES [Vehicle].[Models] ([ModelID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

