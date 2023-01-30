CREATE TABLE [Audit].[VehiclePartyRoleEvents] (
    [AuditItemID]             dbo.AuditItemID       NOT NULL,
    [VehiclePartyRoleEventID] dbo.VehiclePartyRoleEventID          IDENTITY (1, 1) NOT NULL,
    [EventID]                 dbo.EventID       NOT NULL,
    [PartyID]                 dbo.PartyID          NOT NULL,
    [VehicleRoleTypeID]       dbo.VehicleRoleTypeID          NOT NULL,
    [VehicleID]               dbo.VehicleID NOT NULL,
    [ThroughDate]             DATETIME2     NULL
);

