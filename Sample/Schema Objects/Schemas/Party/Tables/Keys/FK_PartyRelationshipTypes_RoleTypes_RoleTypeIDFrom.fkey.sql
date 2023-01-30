ALTER TABLE [Party].[PartyRelationshipTypes]
    ADD CONSTRAINT [FK_PartyRelationshipTypes_RoleTypes_RoleTypeIDFrom] 
    FOREIGN KEY ([RoleTypeIDFrom]) 
    REFERENCES [dbo].[RoleTypes] ([RoleTypeID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

