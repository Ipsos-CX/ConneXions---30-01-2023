CREATE TABLE [Merge].[AutomotiveEventBasedInterviews]
(
	[MergeAuditItemID]              dbo.AuditItemID			NOT NULL,		-- The AuditItemID linked to Merge file
	[MergeAuditRowType]				dbo.MergeAuditRowType	NOT NULL,		-- The type of values in the row e.g. BEFORE or AFTER merge/un-merge
	
    [CaseID]            dbo.CaseID   NOT NULL,
    [EventID]           dbo.EventID   NULL,
    [PartyID]           dbo.PartyID      NULL,
    [VehicleRoleTypeID] dbo.VehicleRoleTypeID NULL,
    [VehicleID]         dbo.VehicleID   NULL
)
