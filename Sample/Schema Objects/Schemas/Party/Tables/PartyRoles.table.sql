CREATE TABLE [Party].[PartyRoles] (
    [PartyID]     dbo.PartyID      NOT NULL,
    [RoleTypeID]  dbo.RoleTypeID NOT NULL,
    [PartyRoleID] dbo.PartyRoleID      IDENTITY (1, 1) NOT NULL,
    [FromDate]    DATETIME2 NOT NULL
);

