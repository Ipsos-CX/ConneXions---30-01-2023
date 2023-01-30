CREATE TABLE [Audit].[CustomerUpdate_Person] (
    [PartyID]                   dbo.PartyID            NOT NULL,
    [CaseID]                    dbo.CaseID         NOT NULL,
    [Title]                     dbo.Title NULL,
    [FirstName]                 dbo.NameDetail NULL,
    [LastName]                  dbo.NameDetail NULL,
    [SecondLastName]            dbo.NameDetail NULL,
    [AuditID]                   dbo.AuditID        NOT NULL,
    [AuditItemID]               dbo.AuditItemID       NOT  NULL,
    [ParentAuditItemID]         dbo.AuditItemID         NULL,
    [TitleID]         dbo.TitleID            NULL,
    [CasePartyCombinationValid] BIT            NOT NULL,
    [DateProcessed]             DATETIME2       NOT NULL
);

