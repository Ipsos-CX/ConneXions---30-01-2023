ALTER TABLE [Party].[IndustryClassifications]
    ADD CONSTRAINT [FK_IndustryClassifications_PartyClassifications] FOREIGN KEY ([PartyTypeID], [PartyID]) 
    REFERENCES [Party].[PartyClassifications] ([PartyTypeID], [PartyID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

