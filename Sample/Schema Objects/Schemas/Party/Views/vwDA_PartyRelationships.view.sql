CREATE VIEW Party.vwDA_PartyRelationships

AS

SELECT	
	CONVERT(BIGINT, 0) AS AuditItemID, 
	PartyIDFrom, 
	RoleTypeIDFrom,
	PartyIDTo,
	RoleTypeIDTo, 
	CONVERT(DATETIME2, NULL) AS FromDate, 
	CONVERT(DATETIME2, NULL) AS ThroughDate, 
	PartyRelationshipTypeID
FROM Party.PartyRelationships
