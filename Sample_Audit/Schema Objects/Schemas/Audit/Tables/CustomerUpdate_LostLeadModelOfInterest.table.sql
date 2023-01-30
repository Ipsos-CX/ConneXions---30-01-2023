CREATE TABLE [Audit].[CustomerUpdate_LostLeadModelOfInterest] (
    [PartyID]                   dbo.PartyID            NOT NULL,
    [CaseID]                    dbo.CaseID         NOT NULL,
    [ModelOfInterest]			dbo.ModelDescription    NULL,
    [AuditID]                   dbo.AuditID         NOT NULL,
    [AuditItemID]               dbo.AuditItemID         NOT NULL,
    [ParentAuditItemID]         dbo.AuditItemID         NULL,
    [CasePartyCombinationValid] BIT            NOT NULL,
    [NewVehicleID]				dbo.VehicleID            NULL,
    [DateProcessed]             DATETIME2       NOT NULL

);

