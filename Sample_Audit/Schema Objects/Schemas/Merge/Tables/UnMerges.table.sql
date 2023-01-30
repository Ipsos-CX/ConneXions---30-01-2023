CREATE TABLE [Merge].[UnMerges]
(
	AuditItemID				dbo.AuditItemID			NOT NULL,		-- The AuditItemID linked to UnMerge file
	
	ParentPartyID			dbo.PartyID				NOT NULL,
	
	Validated				BIT						NOT NULL,
	DateProcessed			DATETIME2				NOT NULL
)
