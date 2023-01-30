CREATE TABLE [CustomerUpdate].[RegistrationNumber] (
	[ID]							INT IDENTITY(1,1) NOT NULL ,
    [PartyID]                       dbo.PartyID            NOT NULL,
    [CaseID]                        dbo.CaseID         NOT NULL,
    [RegNumber]                     dbo.RegistrationNumber NULL,
    [AuditID]                       dbo.AuditID         NULL,
    [AuditItemID]                   dbo.AuditItemID         NULL,
    [ParentAuditItemID]             dbo.AuditItemID         NULL,
    [VehicleRegistrationEventMatch] BIT            NOT NULL,
    [NewRegistrationID]             dbo.RegistrationID            NULL,
    [EventID]                       dbo.EventID            NULL
);

