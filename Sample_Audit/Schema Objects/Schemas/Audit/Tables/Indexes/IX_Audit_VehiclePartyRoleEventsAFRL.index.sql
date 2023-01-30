CREATE NONCLUSTERED INDEX [IX_Audit_VehiclePartyRoleEventsAFRL]
    ON [Audit].[VehiclePartyRoleEventsAFRL]
    ([EventID] ASC, [PartyID] ASC, [VehicleID] ASC)
    INCLUDE([AFRLCode])


