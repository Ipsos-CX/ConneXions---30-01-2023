CREATE TABLE [Audit].[InternalUpdate_UnMergeParties] (
    [AuditID]                   dbo.AuditID         NULL,
    [AuditItemID]               dbo.AuditItemID         NULL,
    [ParentPartyID]             dbo.PartyID            NOT NULL,
    [ParentAuditItemID]         dbo.AuditItemID         NULL,
    [PartyCombinationValid]		BIT					NOT NULL,
    [InvalidReasonID]			INT					NULL,
    DateProcessed				DATETIME2			NULL
);

