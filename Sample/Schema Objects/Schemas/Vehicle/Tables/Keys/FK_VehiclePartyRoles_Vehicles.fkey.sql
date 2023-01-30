ALTER TABLE [Vehicle].[VehiclePartyRoles]
    ADD CONSTRAINT [FK_VehiclePartyRoles_Vehicles] FOREIGN KEY ([VehicleID]) 
    REFERENCES [Vehicle].[Vehicles] ([VehicleID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

