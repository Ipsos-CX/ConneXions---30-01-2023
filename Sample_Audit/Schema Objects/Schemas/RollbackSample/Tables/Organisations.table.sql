CREATE TABLE [RollbackSample].[Organisations]
(
	AuditID						dbo.AuditID			NOT NULL,
    PartyID						dbo.PartyID			NOT NULL,
    OrganisationName			dbo.OrganisationName NOT NULL,
    MergedDate					DATETIME2			NULL,				
	ParentFlag					dbo.ParentFlag		NULL,
	ParentFlagDate				DATETIME2			NULL,
	UnMergedDate				DATETIME2			NULL
 );

