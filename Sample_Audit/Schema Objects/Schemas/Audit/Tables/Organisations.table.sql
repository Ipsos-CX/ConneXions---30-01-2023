CREATE TABLE [Audit].[Organisations] (
    [AuditItemID]              [dbo].[AuditItemID]      NOT NULL,
    [PartyID]                  [dbo].[PartyID]          NOT NULL,
    [FromDate]                 DATETIME2 (7)            NOT NULL,
    [OrganisationName]         [dbo].[OrganisationName] NOT NULL,
    [OrganisationNameChecksum] AS                       (checksum(isnull([OrganisationName],''))) PERSISTED,
	[UseLatestName]				BIT						NOT NULL
);



