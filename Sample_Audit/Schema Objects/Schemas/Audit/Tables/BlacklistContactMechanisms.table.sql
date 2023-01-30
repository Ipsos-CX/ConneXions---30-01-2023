CREATE TABLE [Audit].[BlacklistContactMechanisms] (
    [AuditItemID]                       dbo.AuditItemID   NOT NULL,
    [ContactMechanismID]                dbo.ContactMechanismID      NOT NULL,
    [ContactMechanismTypeID]            dbo.ContactMechanismTypeID NOT NULL,
    [BlacklistStringID]					dbo.BlacklistStringID      NOT NULL,
    [FromDate]                          DATETIME2 NULL,
    [ThroughDate]                       DATETIME2 NULL
);

