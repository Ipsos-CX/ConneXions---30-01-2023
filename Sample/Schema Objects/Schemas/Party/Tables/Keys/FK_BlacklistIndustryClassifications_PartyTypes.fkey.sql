ALTER TABLE [Party].[BlacklistIndustryClassifications]
    ADD CONSTRAINT [FK_BlacklistIndustryClassifications_PartyTypes] FOREIGN KEY ([PartyTypeID]) 
    REFERENCES [Party].[PartyTypes] ([PartyTypeID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

