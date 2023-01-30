CREATE NONCLUSTERED INDEX [IX_PartyDetails_PartyIDTo_RoleTypeIDFrom_RoleTypeIDTo]
    ON [Party].[PartyRelationships]
    ([PartyIDTo] ASC, [RoleTypeIDFrom] ASC, [RoleTypeIDTo] ASC)


