ALTER TABLE [Vehicle].[VehicleRegistrationEvents]
    ADD CONSTRAINT [FK_VehicleRegistrationEvents_Registrations] FOREIGN KEY ([RegistrationID]) 
    REFERENCES [Vehicle].[Registrations] ([RegistrationID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

