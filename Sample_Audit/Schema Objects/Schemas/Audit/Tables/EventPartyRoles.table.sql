CREATE TABLE [Audit].[EventPartyRoles] (
    [AuditItemID]                 [dbo].[AuditItemID] NOT NULL,
    [PartyID]                     [dbo].[PartyID]     NOT NULL,
    [RoleTypeID]                  [dbo].[RoleTypeID]  NOT NULL,
    [EventID]                     [dbo].[EventID]     NOT NULL,
    [DealerCode]                  [dbo].[DealerCode]  NULL,
    [DealerCodeOriginatorPartyID] [dbo].[PartyID]     NULL
);



