ALTER TABLE [Vehicle].[VehiclePartyRoleEvents]
    ADD CONSTRAINT [FK_VehiclePartyRoleEvents_Events] FOREIGN KEY ([EventID]) 
    REFERENCES [Event].[Events] ([EventID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

