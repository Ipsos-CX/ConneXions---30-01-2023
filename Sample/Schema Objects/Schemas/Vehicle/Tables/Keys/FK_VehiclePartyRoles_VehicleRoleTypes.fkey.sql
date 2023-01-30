ALTER TABLE [Vehicle].[VehiclePartyRoles]
    ADD CONSTRAINT [FK_VehiclePartyRoles_VehicleRoleTypes] FOREIGN KEY ([VehicleRoleTypeID]) 
    REFERENCES [Vehicle].[VehicleRoleTypes] ([VehicleRoleTypeID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

