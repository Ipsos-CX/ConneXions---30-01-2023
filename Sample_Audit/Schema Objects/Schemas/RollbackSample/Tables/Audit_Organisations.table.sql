CREATE TABLE [RollbackSample].[Audit_Organisations]
(
	[AuditID]					dbo.AuditID				NOT NULL,
    [AuditItemID]              [dbo].[AuditItemID]      NOT NULL,
    [PartyID]                  [dbo].[PartyID]          NOT NULL,
    [FromDate]                 DATETIME2 (7)            NOT NULL,
    [OrganisationName]         [dbo].[OrganisationName] NOT NULL
 );

