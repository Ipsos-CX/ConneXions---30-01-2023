ALTER TABLE [Party].[PartyRelationships]
    ADD CONSTRAINT [FK_PartyRelationships_PartyRelationshipTypes] 
    FOREIGN KEY ([PartyRelationshipTypeID]) 
    REFERENCES [Party].[PartyRelationshipTypes] ([PartyRelationshipTypeID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

