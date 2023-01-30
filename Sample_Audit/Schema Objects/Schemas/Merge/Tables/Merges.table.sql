CREATE TABLE [Merge].[Merges]
(
	AuditItemID				dbo.AuditItemID			NOT NULL,		-- The AuditItemID linked to Merge file
	
	ParentPartyID			dbo.PartyID				NOT NULL,
	ChildPartyID			dbo.PartyID				NOT NULL,
	
	Validated				BIT						NOT NULL,
	DateMerged				DATETIME2				NOT NULL,
	
	SubsequentlyUnMerged	BIT						NULL,
	UnMergeAuditItemID		dbo.AuditItemID			NULL,
	DateUnMerged			DATETIME2				NULL

)
