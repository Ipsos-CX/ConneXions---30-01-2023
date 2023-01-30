CREATE VIEW Party.vwDA_EmployeeRelationships

AS

SELECT	
	CONVERT(BIGINT, 0) AS AuditItemID, 
	PR.PartyIDFrom, 
	PR.RoleTypeIDFrom,
	PR.PartyIDTo,
	PR.RoleTypeIDTo, 
	CURRENT_TIMESTAMP AS FromDate, 
	CONVERT(DATETIME2, NULL) AS ThroughDate, 
	PR.PartyRelationshipTypeID,
	ER.EmployeeIdentifier, 		
	ER.EmployeeIdentifierUsable 
FROM Party.PartyRelationships AS PR
INNER JOIN Party.EmployeeRelationships AS ER ON ER.PartyIDFrom = PR.PartyIDFrom
								AND ER.PartyIDTo = PR.PartyIDTo
								AND ER.RoleTypeIDFrom = PR.RoleTypeIDFrom
								AND ER.RoleTypeIDTo = PR.RoleTypeIDTo




