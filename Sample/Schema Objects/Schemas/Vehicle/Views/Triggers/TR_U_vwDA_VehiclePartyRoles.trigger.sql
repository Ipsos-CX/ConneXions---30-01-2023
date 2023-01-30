CREATE Trigger [Vehicle].[TR_U_vwDA_VehiclePartyRoles] On [Vehicle].[vwDA_VehiclePartyRoles]

Instead Of Update

As

/*
Description
-----------

Version		Date		Author		Reason
-----------------------------------------------------------------------------------------------------------
1.0		10/05/2004	Rob Mason	Created.

*/


Insert	[Sample_audit].Audit.VehiclePartyRoles
	(
	AuditItemID, 
	PartyID, 
	VehicleRoleTypeID, 
	VehicleID, 
	FromDate, 
	ThroughDate
	)
Select	Distinct 
	i.AuditItemID,
	i.PartyID, 
	i.VehicleRoleTypeID, 
	i.VehicleID,  
	i.FromDate, 
	i.ThroughDate
From	inserted i

Update	VehiclePartyRoles
Set	PartyID = i.PartyID, 
	VehicleRoleTypeID = i.VehicleRoleTypeID, 
	VehicleID = i.VehicleID, 
	FromDate = i.FromDate, 
	ThroughDate = i.ThroughDate	
From	inserted i
Join	VehiclePartyRoles vpr on i.PartyID = vpr.PartyID And i.VehicleRoleTypeID = vpr.VehicleRoleTypeID And i.VehicleID = vpr.VehicleID




GO


