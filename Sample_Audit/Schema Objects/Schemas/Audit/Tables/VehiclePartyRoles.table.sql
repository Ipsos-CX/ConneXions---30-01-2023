CREATE TABLE [Audit].[VehiclePartyRoles] (
    [AuditItemID]       dbo.AuditItemID       NOT NULL,
    [PartyID]           dbo.PartyID          NOT NULL,
    [VehicleRoleTypeID] dbo.VehicleRoleTypeID          NOT NULL,
    [VehicleID]         dbo.VehicleID NOT NULL,
    [FromDate]          DATETIME2     NOT NULL,
    [ThroughDate]       DATETIME2     NULL
);

