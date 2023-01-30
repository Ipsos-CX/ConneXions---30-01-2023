CREATE TABLE [Merge].[PartyContactMechanisms]
(
	[MergeAuditItemID]              dbo.AuditItemID			NOT NULL,		-- The AuditItemID linked to Merge file
	[MergeAuditRowType]				dbo.MergeAuditRowType	NOT NULL,		-- The type of values in the row e.g. BEFORE or AFTER merge/un-merge
	
    [ContactMechanismID]       dbo.ContactMechanismID           NOT NULL,
    [PartyID]                  dbo.PartyID           NOT NULL,
    [RoleTypeID]               dbo.RoleTypeID      NULL,
    [FromDate]                 DATETIME2      NOT NULL
)
