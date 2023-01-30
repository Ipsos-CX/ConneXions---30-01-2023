CREATE TABLE [Merge].[CustomerRelationships]
(
	[MergeAuditItemID]              dbo.AuditItemID			NOT NULL,		-- The AuditItemID linked to Merge file
	[MergeAuditRowType]				dbo.MergeAuditRowType	NOT NULL,		-- The type of values in the row e.g. BEFORE or AFTER merge/un-merge
	
    [PartyIDFrom]              dbo.PartyID           NOT NULL,
    [PartyIDTo]                dbo.PartyID           NOT NULL,
    [RoleTypeIDFrom]           dbo.RoleTypeID      NOT NULL,
    [RoleTypeIDTo]             dbo.RoleTypeID      NOT NULL,
    [CustomerIdentifier]       dbo.CustomerIdentifier NOT NULL,
    [CustomerIdentifierUsable] BIT           NOT NULL
)
