CREATE VIEW Party.vwDA_CustomerRelationships

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
	CR.CustomerIdentifier, 		
	CR.CustomerIdentifierUsable
FROM Party.PartyRelationships PR
INNER JOIN Party.CustomerRelationships CR ON CR.PartyIDFrom = PR.PartyIDFrom
										AND CR.PartyIDTo = PR.PartyIDTo
										AND CR.RoleTypeIDFrom = PR.RoleTypeIDFrom
										AND CR.RoleTypeIDTo = PR.RoleTypeIDTo









