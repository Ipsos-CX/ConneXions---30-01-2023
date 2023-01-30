CREATE TABLE [Audit].[LegalOrganisations] (
    [AuditItemID]              [dbo].[AuditItemID]      NOT NULL,
    [PartyID]                  [dbo].[PartyID]          NOT NULL,
    [LegalName]                [dbo].[OrganisationName] NULL,
    [OrganisationNameChecksum] AS                       (checksum(isnull([LegalName],''))) PERSISTED
);



