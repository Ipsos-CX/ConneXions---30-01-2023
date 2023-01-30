CREATE TABLE [Audit].[PartyRelationships] (
    [AuditItemID]               dbo.AuditItemID         NOT NULL,
    [PartyIDFrom]               dbo.PartyID            NOT NULL,
    [PartyIDTo]                 dbo.PartyID            NOT NULL,
    [RoleTypeIDFrom]            dbo.RoleTypeID       NOT NULL,
    [RoleTypeIDTo]              dbo.RoleTypeID       NOT NULL,
    [PartyRelationshipTypeID]   dbo.PartyRelationshipTypeID            NOT NULL,
    [FromDate]                  DATETIME2       NOT NULL,
    [ThroughDate]               DATETIME2       NULL
);

