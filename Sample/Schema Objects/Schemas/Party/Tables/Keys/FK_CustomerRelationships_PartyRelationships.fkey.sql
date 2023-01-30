ALTER TABLE [Party].[CustomerRelationships]
    ADD CONSTRAINT [FK_CustomerRelationships_PartyRelationships] 
    FOREIGN KEY ([PartyIDFrom], [PartyIDTo], [RoleTypeIDFrom], [RoleTypeIDTo]) 
    REFERENCES [Party].[PartyRelationships] ([PartyIDFrom], [PartyIDTo], [RoleTypeIDFrom], [RoleTypeIDTo]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

