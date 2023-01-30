ALTER TABLE [Party].[PartyClassifications]
    ADD CONSTRAINT [FK_PartyClassifications_PartyTypes] FOREIGN KEY ([PartyTypeID]) 
    REFERENCES [Party].[PartyTypes] ([PartyTypeID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

