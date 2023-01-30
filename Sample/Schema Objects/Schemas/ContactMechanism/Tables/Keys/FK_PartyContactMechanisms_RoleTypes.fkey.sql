ALTER TABLE [ContactMechanism].[PartyContactMechanisms]
    ADD CONSTRAINT [FK_PartyContactMechanisms_RoleTypes] FOREIGN KEY ([RoleTypeID]) 
    REFERENCES [dbo].[RoleTypes] ([RoleTypeID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

