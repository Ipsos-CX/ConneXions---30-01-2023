CREATE TABLE [CustomerUpdate].[LostLeadModelOfInterest] (
	[ID]							INT IDENTITY(1,1) NOT NULL ,
    [PartyID]                   dbo.PartyID            NOT NULL,
    [CaseID]                    dbo.CaseID         NOT NULL,
    [ModelOfInterest]           dbo.ModelDescription NOT NULL,
    [AuditID]                   dbo.AuditID         NULL,
    [AuditItemID]               dbo.AuditItemID         NULL,
    [ParentAuditItemID]         dbo.AuditItemID         NULL,
    [CasePartyCombinationValid] BIT            NOT NULL,
    [NewVehicleID]				dbo.VehicleID            NULL,
);

