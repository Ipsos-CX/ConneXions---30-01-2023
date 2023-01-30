CREATE TABLE [Vehicle].[VehiclePartyRoles] (
    [PartyID]           dbo.PartyID      NOT NULL,
    [VehicleRoleTypeID] dbo.RoleTypeID NOT NULL,
    [VehicleID]         dbo.VehicleID   NOT NULL,
    [FromDate]          DATETIME2 NOT NULL,
    [ThroughDate]       DATETIME2 NULL
);

