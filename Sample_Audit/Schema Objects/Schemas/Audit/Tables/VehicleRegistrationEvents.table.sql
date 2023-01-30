CREATE TABLE [Audit].[VehicleRegistrationEvents] (
    [AuditItemID]    dbo.AuditItemID NOT NULL,
    [VehicleID]      dbo.VehicleID NOT NULL,
    [RegistrationID] dbo.RegistrationID    NOT NULL,
    [EventID]        dbo.EventID NOT NULL
);

