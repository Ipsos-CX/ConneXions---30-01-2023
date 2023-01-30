CREATE TABLE [OWAP].[Actions] (
    [AuditItemID]     dbo.AuditItemID   NOT NULL,
    [UserPartyID]   dbo.PartyID      NOT NULL,
    [UserRoleTypeID]      dbo.RoleTypeID      NULL,
    [ActionDate] DATETIME2 NOT NULL
);

