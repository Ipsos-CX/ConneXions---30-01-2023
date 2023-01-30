CREATE TABLE [Audit].[PartyContactMechanisms] (
    [AuditItemID]              dbo.AuditItemID        NOT NULL,
    [ContactMechanismID]       dbo.ContactMechanismID           NOT NULL,
    [PartyID]                  dbo.PartyID           NOT NULL,
    [RoleTypeID]               dbo.RoleTypeID           NULL,
    [FromDate]                 DATETIME2      NOT NULL,
    [ThroughDate]              DATETIME2      NULL
);

