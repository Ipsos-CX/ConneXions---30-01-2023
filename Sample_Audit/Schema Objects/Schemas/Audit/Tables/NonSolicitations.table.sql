CREATE TABLE [Audit].[NonSolicitations] (
    [AuditItemID]           dbo.AuditItemID          NOT NULL,
    [NonSolicitationID]     dbo.NonSolicitationID             NOT NULL,
    [NonSolicitationTextID] dbo.NonSolicitationTextID        NOT NULL,
    [PartyID]               dbo.PartyID             NOT NULL,
    [RoleTypeID]            dbo.RoleTypeID        NULL,
    [FromDate]              DATETIME2        NULL,
    [ThroughDate]           DATETIME2        NULL,
    [Notes]                 VARCHAR(1000) NULL,
    HardSet					INT NULL
);

