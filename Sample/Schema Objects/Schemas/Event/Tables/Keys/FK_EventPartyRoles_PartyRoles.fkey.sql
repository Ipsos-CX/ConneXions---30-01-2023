ALTER TABLE [Event].[EventPartyRoles]
    ADD CONSTRAINT [FK_EventPartyRoles_PartyRoles] FOREIGN KEY ([PartyID], [RoleTypeID]) 
    REFERENCES [Party].[PartyRoles] ([PartyID], [RoleTypeID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

