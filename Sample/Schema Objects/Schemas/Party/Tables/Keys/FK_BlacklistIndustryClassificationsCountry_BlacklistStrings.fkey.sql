ALTER TABLE [Party].[BlacklistIndustryClassificationsCountry]
    ADD CONSTRAINT [FK_BlacklistIndustryClassificationsCountry_BlacklistStrings] FOREIGN KEY ([BlacklistStringID]) 
    REFERENCES [Party].[BlacklistStrings] ([BlacklistStringID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

