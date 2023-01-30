ALTER TABLE [ContactMechanism].[DealerCountries]
    ADD CONSTRAINT [FK_DealerCountries_DealerNetworks] 
    FOREIGN KEY ([PartyIDFrom], [PartyIDTo], [RoleTypeIDFrom], [RoleTypeIDTo], [DealerCode]) 
    REFERENCES [Party].[DealerNetworks] ([PartyIDFrom], [PartyIDTo], [RoleTypeIDFrom], [RoleTypeIDTo], [DealerCode]) 
    ON DELETE CASCADE ON UPDATE CASCADE;

