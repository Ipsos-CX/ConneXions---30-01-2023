CREATE TABLE [RollbackSample].[Audit_LegalOrganisations]
(
	[AuditID]					dbo.AuditID				NOT NULL,
    [AuditItemID]              [dbo].[AuditItemID]      NOT NULL,
    [PartyID]                  [dbo].[PartyID]          NOT NULL,
    [LegalName]                [dbo].[OrganisationName] NULL
);


