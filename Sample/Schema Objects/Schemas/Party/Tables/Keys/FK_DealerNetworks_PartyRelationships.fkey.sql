ALTER TABLE [Party].[DealerNetworks]
    ADD CONSTRAINT [FK_DealerNetworks_PartyRelationships] 
    FOREIGN KEY ([PartyIDFrom], [PartyIDTo], [RoleTypeIDFrom], [RoleTypeIDTo]) 
    REFERENCES [Party].[PartyRelationships] ([PartyIDFrom], [PartyIDTo], [RoleTypeIDFrom], [RoleTypeIDTo]) 
    ON DELETE CASCADE ON UPDATE CASCADE;

