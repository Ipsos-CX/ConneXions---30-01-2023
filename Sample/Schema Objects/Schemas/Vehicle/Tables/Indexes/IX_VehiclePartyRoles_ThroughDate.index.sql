CREATE NONCLUSTERED INDEX [IX_VehiclePartyRoles_ThroughDate]
ON [Vehicle].[VehiclePartyRoles] ([ThroughDate],[VehicleID])
INCLUDE ([PartyID])

