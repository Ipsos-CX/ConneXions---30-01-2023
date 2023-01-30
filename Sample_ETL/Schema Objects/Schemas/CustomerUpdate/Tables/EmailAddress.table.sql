CREATE TABLE [CustomerUpdate].[EmailAddress] (
    [ID]                              INT            IDENTITY (1, 1) NOT NULL,
    [PartyID]                         dbo.PartyID            NOT NULL,
    [CaseID]                          dbo.CaseID         NOT NULL,
    [EmailAddress]               dbo.EmailAddress NULL,
    [ContactMechanismPurposeType] VARCHAR (255)  NULL,
    [ContactMechanismPurposeTypeID]   dbo.ContactMechanismPurposeTypeID       NULL,
    [ContactMechanismID]              dbo.ContactMechanismID            NULL,
    [AuditID]                         dbo.AuditID         NULL,
    [AuditItemID]                     dbo.AuditItemID         NULL,
    [CasePartyCombinationValid]       BIT            NOT NULL,
    [ParentAuditItemID]               dbo.AuditItemID         NULL,
    [EmailIsCurrentForParty]          BIT            NOT NULL
);

