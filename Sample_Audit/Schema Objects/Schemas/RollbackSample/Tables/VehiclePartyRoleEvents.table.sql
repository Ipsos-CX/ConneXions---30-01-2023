CREATE TABLE [RollbackSample].[VehiclePartyRoleEvents]
(
	[AuditID]				dbo.AuditID				NOT NULL,
    [VehiclePartyRoleEventID] dbo.VehiclePartyRoleEventID  NOT NULL,
    [EventID]                 dbo.EventID   NOT NULL,
    [PartyID]                 dbo.PartyID      NOT NULL,
    [VehicleRoleTypeID]       dbo.VehicleRoleTypeID NOT NULL,
    [VehicleID]               dbo.VehicleID   NOT NULL,
    [FromDate]                DATETIME2 NOT NULL,
    [AFRLCode]				  dbo.AFRLCode NULL
);

