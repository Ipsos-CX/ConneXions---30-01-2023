CREATE TABLE [Merge].[VehiclePartyRoleEvents]
(
	[MergeAuditItemID]              dbo.AuditItemID			NOT NULL,		-- The AuditItemID linked to Merge file
	[MergeAuditRowType]				dbo.MergeAuditRowType	NOT NULL,		-- The type of values in the row e.g. BEFORE or AFTER merge/un-merge

    [VehiclePartyRoleEventID] dbo.VehiclePartyRoleEventID   IDENTITY (1, 1) NOT NULL,
    [EventID]                 dbo.EventID   NOT NULL,
    [PartyID]                 dbo.PartyID      NOT NULL,
    [VehicleRoleTypeID]       dbo.VehicleRoleTypeID NOT NULL,
    [VehicleID]               dbo.VehicleID   NOT NULL,
    [FromDate]                DATETIME2 NOT NULL,
    [AFRLCode]				  dbo.AFRLCode NULL
)
