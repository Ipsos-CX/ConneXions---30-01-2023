ALTER TABLE [Party].[BlacklistIndustryClassifications]
    ADD CONSTRAINT [FK_BlacklistIndustryClassifications_PartyExclusionCategories] FOREIGN KEY (PartyExclusioncategoryID) 
    REFERENCES [Party].[PartyExclusioncategories] (PartyExclusioncategoryID) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

