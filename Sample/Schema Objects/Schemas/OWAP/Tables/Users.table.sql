CREATE TABLE [OWAP].[Users] (
    [PartyID]    dbo.PartyID            NOT NULL,
    [RoleTypeID] dbo.RoleTypeID       NOT NULL,
    [UserName]   VARCHAR(100) NOT NULL,
    [Password]   VARCHAR(255)  NOT NULL
);

