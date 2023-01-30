CREATE TABLE [CustomerUpdate].[Dealer] (
	[ID]							INT IDENTITY(1,1) NOT NULL ,
    [PartyID]              dbo.PartyID           NOT NULL,
    [CaseID]               dbo.CaseID        NOT NULL,
    [DealerPartyID]        dbo.PartyID           NOT NULL,
    [EventID]              dbo.EventID        NULL,
    [RoleTypeID]           dbo.RoleTypeID           NULL,
    [DealerCode]           dbo.DealerCode NULL,
    [ManufacturerPartyID]  dbo.PartyID           NULL,
    [AuditID]              dbo.AuditID        NULL,
    [AuditItemID]          dbo.AuditItemID        NULL,
    [ParentAuditItemID]    dbo.AuditItemID        NULL,
    [DealerPartyIDValid]   BIT           NOT NULL,
    [DeleteEventPartyRole] BIT           NOT NULL,
    [NewDealer]            BIT           NOT NULL
);

