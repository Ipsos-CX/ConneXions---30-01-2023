CREATE TABLE [Party].[PartyRelationships] (
    [PartyIDFrom]               dbo.PartyID            NOT NULL,
    [PartyIDTo]                 dbo.PartyID            NOT NULL,
    [RoleTypeIDFrom]            dbo.RoleTypeID       NOT NULL,
    [RoleTypeIDTo]              dbo.RoleTypeID       NOT NULL,
    [FromDate]                  DATETIME2       NOT NULL,
    [PartyRelationshipTypeID]   dbo.PartyRelationshipTypeID            NOT NULL
);

