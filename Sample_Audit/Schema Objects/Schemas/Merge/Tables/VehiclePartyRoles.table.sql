CREATE TABLE [Merge].[VehiclePartyRoles]
(
	[MergeAuditItemID]              dbo.AuditItemID			NOT NULL,		-- The AuditItemID linked to Merge file
	[MergeAuditRowType]				dbo.MergeAuditRowType	NOT NULL,		-- The type of values in the row e.g. BEFORE or AFTER merge/un-merge
	 
    [PartyID]           dbo.PartyID      NOT NULL,
    [VehicleRoleTypeID] dbo.RoleTypeID NOT NULL,
    [VehicleID]         dbo.VehicleID   NOT NULL,
    [FromDate]          DATETIME2 NOT NULL,
    [ThroughDate]       DATETIME2 NULL
)
