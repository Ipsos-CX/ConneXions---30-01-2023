CREATE NONCLUSTERED INDEX [IX_VehiclePartyRoleEvents_VehicleRoleTypeIDPlus]
ON [Vehicle].[VehiclePartyRoleEvents] ([VehicleRoleTypeID])
INCLUDE ([EventID],[VehicleID],[FromDate])

