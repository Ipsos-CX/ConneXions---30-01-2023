CREATE TABLE [Audit].[CustomerUpdate_EmailAddress] (
    [PartyID]                         dbo.PartyID            NOT NULL,
    [CaseID]                          dbo.CaseID         NOT NULL,
    [EmailAddress]               dbo.EmailAddress NULL,
    [ContactMechanismPurposeType] VARCHAR(255)  NULL,
    [ContactMechanismPurposeTypeID]   dbo.ContactMechanismPurposeTypeID       NULL,
    [ContactMechanismID]              dbo.ContactMechanismID            NULL,
    [AuditID]                         dbo.AuditID         NOT NULL,
    [AuditItemID]                     dbo.AuditItemID        NOT NULL,
    [CasePartyCombinationValid]       BIT            NOT NULL,
    [ParentAuditItemID]               dbo.AuditItemID         NULL,
    [DateProcessed]                   DATETIME2      NOT NULL
);

