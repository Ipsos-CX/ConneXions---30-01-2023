CREATE TABLE [Audit].[CustomerUpdate_Dealer] (
    [PartyID]              dbo.PartyID           NOT NULL,
    [CaseID]               dbo.CaseID        NOT NULL,
    [DealerPartyID]        dbo.PartyID           NOT NULL,
    [EventID]              dbo.EventID        NULL,
    [RoleTypeID]           dbo.RoleTypeID           NULL,
    [DealerCode]           dbo.DealerCode NULL,
    [ManufacturerPartyID]  dbo.PartyID           NULL,
    [AuditID]              dbo.AuditID       NOT NULL,
    [AuditItemID]          dbo.AuditItemID       NOT NULL,
    [ParentAuditItemID]    dbo.AuditItemID        NULL,
    [DealerPartyIDValid]   BIT           NOT NULL,
    [DeleteEventPartyRole] BIT           NOT NULL,
    [NewDealer]            BIT           NOT NULL,
    [DateProcessed]        DATETIME2     NOT NULL
);

