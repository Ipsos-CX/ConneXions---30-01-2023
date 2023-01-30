CREATE TABLE [InternalUpdate].[UnMergeParties] (
	[ID]						INT IDENTITY(1,1) NOT NULL ,
    [ParentPartyID]             dbo.PartyID            NOT NULL,
    [AuditID]                   dbo.AuditID         NULL,
    [AuditItemID]               dbo.AuditItemID         NULL,
    [ParentAuditItemID]         dbo.AuditItemID         NULL,
    [PartyCombinationValid]		BIT					NOT NULL,
    [InvalidReasonID]			INT					NULL
);

