CREATE TABLE [Party].[Organisations] (
    [PartyID] dbo.PartyID NOT NULL,
    [OrganisationName] dbo.OrganisationName NOT NULL,
    [OrganisationNameChecksum] AS (CHECKSUM(ISNULL([OrganisationName],''))) PERSISTED,
    MergedDate					DATETIME2			NULL,				
	ParentFlag					dbo.ParentFlag		NULL,
	ParentFlagDate				DATETIME2			NULL,
	UnMergedDate				DATETIME2			NULL,
	UseLatestName				BIT					NOT NULL
);

