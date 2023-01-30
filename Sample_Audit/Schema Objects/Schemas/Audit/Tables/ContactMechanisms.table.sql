CREATE TABLE [Audit].[ContactMechanisms] (
    [AuditItemID]            dbo.AuditItemID   NOT NULL,
    [ContactMechanismID]     dbo.ContactMechanismID      NOT NULL,
    [ContactMechanismTypeID] dbo.ContactMechanismTypeID NOT NULL,
    [Valid]                  BIT      NOT NULL
);

