CREATE TABLE [Audit].[CustomerUpdate_SMSBouncebacks] (
    [PartyID]                        dbo.PartyID        NOT NULL,
    [CaseID]                         dbo.CaseID         NOT NULL,
    [ContactMechanismID]             dbo.ContactMechanismID   NULL,
    [MobileNumber]					dbo.ContactNumber			NULL,
    [OutcomeCode]                    dbo.OutcomeCode    NOT NULL,
    [AuditID]                        dbo.AuditID        NOT NULL,
    [AuditItemID]                    dbo.AuditItemID    NOT NULL,
    [ParentAuditItemID]              dbo.AuditItemID    NULL,
    [CasePartyMobileCombinationValid] BIT            NOT NULL,
    [DateLoaded]                     DATETIME2       NOT NULL,
    [DateProcessed]                  DATETIME2       NULL
);

