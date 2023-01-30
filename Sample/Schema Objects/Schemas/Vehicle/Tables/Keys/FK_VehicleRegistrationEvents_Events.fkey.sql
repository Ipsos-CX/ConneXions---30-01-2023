ALTER TABLE [Vehicle].[VehicleRegistrationEvents]
    ADD CONSTRAINT [FK_VehicleRegistrationEvents_Events] FOREIGN KEY ([EventID]) 
    REFERENCES [Event].[Events] ([EventID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

