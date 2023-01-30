CREATE TABLE [RollbackSample].[PartyContactMechanismPurposes]
(
	[AuditID]				dbo.AuditID				NOT NULL,
    [ContactMechanismID]            dbo.ContactMechanismID      NOT NULL,
    [PartyID]                       dbo.PartyID      NOT NULL,
    [ContactMechanismPurposeTypeID] dbo.ContactMechanismPurposeTypeID NOT NULL,
    [FromDate]                      DATETIME2 NOT NULL
 );

