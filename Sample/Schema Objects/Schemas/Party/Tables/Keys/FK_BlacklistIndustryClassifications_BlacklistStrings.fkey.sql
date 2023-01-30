ALTER TABLE [Party].[BlacklistIndustryClassifications]
    ADD CONSTRAINT [FK_BlacklistIndustryClassifications_BlacklistStrings] FOREIGN KEY ([BlacklistStringID]) 
    REFERENCES [Party].[BlacklistStrings] ([BlacklistStringID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

