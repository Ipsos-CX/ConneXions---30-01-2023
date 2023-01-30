CREATE TABLE [Audit].[LegalOrganisationsByLanguage] (
    [AuditItemID]              [dbo].[AuditItemID]      NOT NULL,
    [PartyID]                  [dbo].[PartyID]          NOT NULL,
    [LegalName]                [dbo].[OrganisationName] NULL,
    [LanguageID]			   [dbo].[LanguageID]		NOT NULL
);