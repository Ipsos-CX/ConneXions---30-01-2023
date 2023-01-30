CREATE TABLE [Party].[CustomerRelationships] (
    [PartyIDFrom]              dbo.PartyID           NOT NULL,
    [PartyIDTo]                dbo.PartyID           NOT NULL,
    [RoleTypeIDFrom]           dbo.RoleTypeID      NOT NULL,
    [RoleTypeIDTo]             dbo.RoleTypeID      NOT NULL,
    [CustomerIdentifier]       dbo.CustomerIdentifier NOT NULL,
    [CustomerIdentifierUsable] BIT           NOT NULL
);

