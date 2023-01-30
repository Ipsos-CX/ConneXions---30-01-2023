CREATE TABLE [Merge].[UnMergeChildren]
(
	AuditItemID				dbo.AuditItemID			NOT NULL,		-- The AuditItemID linked to UnMerge file
	
	ChildPartyID			dbo.PartyID				NOT NULL,
	ChildAuditItemID		dbo.AuditItemID			NOT NULL		-- The AuditItemID of the Merge Audit record
)
