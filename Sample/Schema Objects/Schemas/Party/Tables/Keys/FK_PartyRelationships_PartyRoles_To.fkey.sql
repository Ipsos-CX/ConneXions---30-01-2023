ALTER TABLE [Party].[PartyRelationships]
    ADD CONSTRAINT [FK_PartyRelationships_PartyRoles_To] 
    FOREIGN KEY ([PartyIDTo], [RoleTypeIDTo]) 
    REFERENCES [Party].[PartyRoles] ([PartyID], [RoleTypeID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

