ALTER TABLE [Party].[EmployeeRelationships]
    ADD CONSTRAINT [FK_EmployeeRelationships_PartyRelationships] 
    FOREIGN KEY ([PartyIDFrom], [PartyIDTo], [RoleTypeIDFrom], [RoleTypeIDTo]) 
    REFERENCES [Party].[PartyRelationships] ([PartyIDFrom], [PartyIDTo], [RoleTypeIDFrom], [RoleTypeIDTo]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

