ALTER TABLE [Party].[RoadsideNetworks]
	ADD CONSTRAINT [FK_RoadsideNetworks_PartyRelationships] 
    FOREIGN KEY ([PartyIDFrom], [PartyIDTo], [RoleTypeIDFrom], [RoleTypeIDTo]) 
    REFERENCES [Party].[PartyRelationships] ([PartyIDFrom], [PartyIDTo], [RoleTypeIDFrom], [RoleTypeIDTo]) 
    ON DELETE CASCADE ON UPDATE CASCADE;
