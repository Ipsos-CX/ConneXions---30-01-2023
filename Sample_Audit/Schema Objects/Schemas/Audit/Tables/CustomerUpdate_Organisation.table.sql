CREATE TABLE [Audit].[CustomerUpdate_Organisation] (
    [PartyID]                   dbo.PartyID            NOT NULL,
    [CaseID]                    dbo.CaseID         NOT NULL,
    [OrganisationName]          dbo.OrganisationName NULL,
    [AuditID]                   dbo.AuditID         NOT NULL,
    [AuditItemID]               dbo.AuditItemID         NOT NULL,
    [ParentAuditItemID]         dbo.AuditItemID         NULL,
    [CasePartyCombinationValid] BIT            NOT NULL,
    [OrganisationPartyID]       dbo.PartyID            NULL,
    [PartyTypeFlag]             VARCHAR(10)      NULL,
    [DateProcessed]             DATETIME2       NOT NULL
);

