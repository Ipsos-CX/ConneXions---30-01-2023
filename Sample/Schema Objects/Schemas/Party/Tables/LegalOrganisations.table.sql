CREATE TABLE [Party].[LegalOrganisations] (
    [PartyID]   dbo.PartyID            NOT NULL,
    [LegalName] dbo.OrganisationName NULL,
    [OrganisationNameChecksum] AS (CHECKSUM(ISNULL([LegalName],''))) PERSISTED
);

