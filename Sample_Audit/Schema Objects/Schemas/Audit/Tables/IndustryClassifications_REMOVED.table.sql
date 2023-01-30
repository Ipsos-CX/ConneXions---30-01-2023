CREATE TABLE [Audit].[IndustryClassifications_REMOVED] (
    [AuditItemID] dbo.AuditItemID   NOT NULL,
    [PartyTypeID] dbo.PartyTypeID NOT NULL,
    [PartyID]     dbo.PartyID      NOT NULL,
    [FromDate]    DATETIME2 NOT NULL,
    [RemovedDate] DATETIME2 NOT NULL
);

