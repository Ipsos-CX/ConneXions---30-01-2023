CREATE TABLE [Audit].[VehiclePartyRoleEventsAFRL] (
    [AuditItemID]             dbo.AuditItemID       NOT NULL,
    [VehiclePartyRoleEventID] dbo.VehiclePartyRoleEventID   NOT NULL,
    [EventID]                 dbo.EventID       NOT NULL,
    [PartyID]                 dbo.PartyID          NOT NULL,
    [VehicleRoleTypeID]       dbo.VehicleRoleTypeID          NOT NULL,
    [VehicleID]               dbo.VehicleID NOT NULL,
    [AFRLCode]				  dbo.AFRLCode NULL,
    [ThroughDate]             DATETIME2     NULL
);

