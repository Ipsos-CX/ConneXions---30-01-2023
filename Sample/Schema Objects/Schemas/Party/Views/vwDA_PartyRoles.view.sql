CREATE VIEW Party.vwDA_PartyRoles

AS

SELECT	
	CONVERT(BIGINT, 0) AS AuditItemID, 
	PartyID, 
	RoleTypeID, 
	CONVERT(DATETIME2, NULL) AS FromDate, 
	CONVERT(DATETIME2, NULL) AS ThroughDate
FROM Party.PartyRoles







