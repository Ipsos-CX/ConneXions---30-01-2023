CREATE TABLE [Audit].[PartyRoles] (
    [AuditItemID] dbo.AuditItemID   NOT NULL,
    [PartyRoleID] dbo.PartyRoleID      NOT NULL,
    [PartyID]     dbo.PartyID      NOT NULL,
    [RoleTypeID]  dbo.RoleTypeID NOT NULL,
    [FromDate]    DATETIME2 NOT NULL,
    [ThroughDate] DATETIME2 NULL
);

