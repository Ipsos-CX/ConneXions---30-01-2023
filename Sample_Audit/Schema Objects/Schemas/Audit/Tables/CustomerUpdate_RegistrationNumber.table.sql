CREATE TABLE [Audit].[CustomerUpdate_RegistrationNumber] (
    [PartyID]           dbo.PartyID            NOT NULL,
    [CaseID]            dbo.CaseID         NOT NULL,
    [RegNumber]         dbo.RegistrationNumber NULL,
    [AuditID]           dbo.AuditID         NOT NULL,
    [AuditItemID]       dbo.AuditItemID         NOT NULL,
    [ParentAuditItemID] dbo.AuditItemID         NULL,
    [EventID]		    dbo.EventID				NULL,
    [VehicleRegistrationEventMatch]  BIT	NULL,
    [RegistrationID]	dbo.RegistrationID NULL,
    [DateProcessed]     DATETIME2       NOT NULL
);

