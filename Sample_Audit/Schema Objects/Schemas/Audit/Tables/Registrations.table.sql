CREATE TABLE [Audit].[Registrations] (
    [AuditItemID]            dbo.AuditItemID        NOT NULL,
    [RegistrationID]         dbo.RegistrationID     NOT NULL,
    [RegistrationNumber]     dbo.RegistrationNumber NULL,
    [RegistrationDateOrig]   VARCHAR(50)  NULL,
    [RegistrationDate]       DATETIME2      NULL,
    [ThroughDate]            DATETIME2      NULL
);

