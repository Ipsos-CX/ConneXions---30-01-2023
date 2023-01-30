ALTER TABLE [Party].[PartyRelationships]
    ADD CONSTRAINT [FK_PartyRelationships_PartyRoles_From] 
    FOREIGN KEY ([PartyIDFrom], [RoleTypeIDFrom]) 
    REFERENCES [Party].[PartyRoles] ([PartyID], [RoleTypeID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

