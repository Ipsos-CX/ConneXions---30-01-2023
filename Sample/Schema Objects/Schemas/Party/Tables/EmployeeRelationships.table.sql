CREATE TABLE [Party].[EmployeeRelationships] (
    [PartyIDFrom]              dbo.PartyID           NOT NULL,
    [PartyIDTo]                dbo.PartyID           NOT NULL,
    [RoleTypeIDFrom]           dbo.RoleTypeID      NOT NULL,
    [RoleTypeIDTo]             dbo.RoleTypeID      NOT NULL,
    [EmployeeIdentifier]       dbo.EmployeeIdentifier NOT NULL,
    [EmployeeIdentifierUsable] BIT           NOT NULL
);

