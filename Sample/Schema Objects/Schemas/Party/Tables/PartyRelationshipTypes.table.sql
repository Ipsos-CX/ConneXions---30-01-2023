CREATE TABLE [Party].[PartyRelationshipTypes] (
    [PartyRelationshipTypeID]   dbo.PartyRelationshipTypeID           NOT NULL,
    [RoleTypeIDFrom]       dbo.RoleTypeID      NOT NULL,
    [RoleTypeIDTo]         dbo.RoleTypeID      NOT NULL,
    [PartyRelationshipTypeDescription] VARCHAR (255) NOT NULL,
    [PartyRelationshipTypeName] VARCHAR (75)  NOT NULL
);

