CREATE TABLE [Audit].[InternalUpdate_MergeParties] (
    [AuditID]                   dbo.AuditID				NULL,
    [AuditItemID]               dbo.AuditItemID         NULL,
 	[ParentPartyID]             dbo.PartyID            NOT NULL,
    [ChildPartyID]              dbo.PartyID            NOT NULL,
    [ParentAuditItemID]         dbo.AuditItemID         NULL,
    [PartyCombinationValid]		BIT					NOT NULL,
    [InvalidReasonID]			INT					NULL,
    DateProcessed				DATETIME2			NULL
);

