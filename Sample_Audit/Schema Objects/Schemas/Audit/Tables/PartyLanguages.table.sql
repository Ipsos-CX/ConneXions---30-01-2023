CREATE TABLE [Audit].[PartyLanguages] (
    [AuditItemID]   dbo.AuditItemID   NOT NULL,
    [PartyID]       dbo.PartyID      NOT NULL,
    [LanguageID]    dbo.LanguageID NOT NULL,
    [FromDate]      DATETIME2 NOT NULL,
    [ThroughDate]   DATETIME2 NULL,
    [PreferredFlag] BIT      NOT NULL
);

