ALTER TABLE [Party].[PartyTypes]
    ADD CONSTRAINT [FK_PartyTypes_PartyExclusionCategories] FOREIGN KEY (DefaultPartyExclusionCategoryID) 
    REFERENCES [Party].[PartyExclusionCategories] (PartyExclusionCategoryID) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

