CREATE TABLE [Vehicle].[VehiclePartyRoleEvents] (
    [VehiclePartyRoleEventID] dbo.VehiclePartyRoleEventID   IDENTITY (1, 1) NOT NULL,
    [EventID]                 dbo.EventID   NOT NULL,
    [PartyID]                 dbo.PartyID      NOT NULL,
    [VehicleRoleTypeID]       dbo.VehicleRoleTypeID NOT NULL,
    [VehicleID]               dbo.VehicleID   NOT NULL,
    [FromDate]                DATETIME2 NOT NULL,
    [AFRLCode]				  dbo.AFRLCode NULL
);

