ALTER TABLE [Party].[PartyRelationshipTypes]
    ADD CONSTRAINT [FK_PartyRelationshipTypes_RoleTypes_RoleTypeIDTo] FOREIGN KEY ([RoleTypeIDTo]) REFERENCES [dbo].[RoleTypes] ([RoleTypeID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

