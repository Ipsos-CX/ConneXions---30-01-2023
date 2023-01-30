CREATE VIEW Vehicle.vwDA_VehiclePartyRoles

AS

SELECT     
	CONVERT(BIGINT, 0) AS AuditItemID, 
	PartyID, 
	VehicleRoleTypeID, 
	VehicleID, 
	FromDate,
	ThroughDate
FROM Vehicle.VehiclePartyRoles


