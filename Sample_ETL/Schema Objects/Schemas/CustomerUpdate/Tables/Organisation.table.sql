CREATE TABLE [CustomerUpdate].[Organisation] (
	[ID]							INT IDENTITY(1,1) NOT NULL ,
    [PartyID]                   dbo.PartyID            NOT NULL,
    [CaseID]                    dbo.CaseID         NOT NULL,
    [OrganisationName]          dbo.OrganisationName NOT NULL,
    [AuditID]                   dbo.AuditID         NULL,
    [AuditItemID]               dbo.AuditItemID         NULL,
    [ParentAuditItemID]         dbo.AuditItemID         NULL,
    [CasePartyCombinationValid] BIT            NOT NULL,
    [OrganisationPartyID]       dbo.PartyID            NULL,
    [PartyTypeFlag]             VARCHAR(10)      NULL
);

