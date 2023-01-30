ALTER TABLE [Party].[PartyRoles]
    ADD CONSTRAINT [FK_PartyRoles_RoleTypeID] FOREIGN KEY ([RoleTypeID]) REFERENCES [dbo].[RoleTypes] ([RoleTypeID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

