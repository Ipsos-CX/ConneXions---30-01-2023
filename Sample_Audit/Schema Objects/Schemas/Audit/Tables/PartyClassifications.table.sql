CREATE TABLE [Audit].[PartyClassifications] (
    [AuditItemID] dbo.AuditItemID   NOT NULL,
    [PartyTypeID] dbo.PartyTypeID NOT NULL,
    [PartyID]     dbo.PartyID      NOT NULL,
    [FromDate]    DATETIME2 NOT NULL,
    [ThroughDate] DATETIME2 NULL
);

