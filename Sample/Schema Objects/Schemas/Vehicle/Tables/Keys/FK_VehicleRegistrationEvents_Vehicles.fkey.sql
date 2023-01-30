ALTER TABLE [Vehicle].[VehicleRegistrationEvents]
    ADD CONSTRAINT [FK_VehicleRegistrationEvents_Vehicles] FOREIGN KEY ([VehicleID]) 
    REFERENCES [Vehicle].[Vehicles] ([VehicleID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

