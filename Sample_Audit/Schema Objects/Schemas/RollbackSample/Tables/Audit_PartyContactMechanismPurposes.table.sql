CREATE TABLE [RollbackSample].[Audit_PartyContactMechanismPurposes]
(
	[AuditID]						dbo.AuditID			NOT NULL,
    [AuditItemID]                   dbo.AuditItemID		NOT NULL,
    [ContactMechanismID]            dbo.ContactMechanismID  NOT NULL,
    [PartyID]                       dbo.PartyID			NOT NULL,
    [ContactMechanismPurposeTypeID] dbo.ContactMechanismPurposeTypeID  NOT NULL,
    [FromDate]                      DATETIME2			NOT NULL,
    [ThroughDate]                   DATETIME2			NULL
);

