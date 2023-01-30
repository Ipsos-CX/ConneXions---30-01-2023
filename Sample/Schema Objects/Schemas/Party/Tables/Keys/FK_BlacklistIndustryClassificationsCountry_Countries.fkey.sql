ALTER TABLE [Party].[BlacklistIndustryClassificationsCountry]
    ADD CONSTRAINT [FK_BlacklistIndustryClassificationsCountry_Countries] FOREIGN KEY ([CountryID]) 
    REFERENCES [ContactMechanism].[Countries] ([CountryID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

