CREATE  VIEW Load.vwCustomerRelationships

AS

-- PEOPLE CUSTOMERS
SELECT
	AuditItemID, 
	MatchedODSPersonID AS PartyIDFrom, 
	(SELECT RoleTypeID FROM [$(SampleDB)].dbo.RoleTypes WHERE RoleType = 'Customer') AS RoleTypeIDFrom,
	ManufacturerID AS PartyIDTo,
	(SELECT RoleTypeID FROM [$(SampleDB)].dbo.RoleTypes WHERE RoleType = 'Manufacturer') AS RoleTypeIDTo,
	CURRENT_TIMESTAMP AS FromDate, 
	CONVERT(DATETIME2, NULL) AS ThroughDate, 
	(SELECT PartyRelationshipTypeID FROM [$(SampleDB)].Party.PartyRelationshipTypes WHERE PartyRelationshipTypeName = 'Manufacturer Customer Relationship') AS PartyRelationshipTypeID,
	ISNULL(CustomerIdentifier, '') AS CustomerIdentifier, 
	CustomerIdentifierUsable, 
	CustomerIdentifierOriginatorPartyID
FROM dbo.VWT
WHERE ISNULL(MatchedODSPersonID, 0) > 0 
AND ISNULL(ManufacturerID, 0) > 0
AND NULLIF(CustomerIdentifier, '') IS NOT NULL
	
UNION

-- ORGANISATION CUSTOMERS
SELECT
	AuditItemID, 
	MatchedODSOrganisationID AS PartyIDFrom, 
	(SELECT RoleTypeID FROM [$(SampleDB)].dbo.RoleTypes WHERE RoleType = 'Customer') AS RoleTypeIDFrom,
	ManufacturerID AS PartyIDTo,
	(SELECT RoleTypeID FROM [$(SampleDB)].dbo.RoleTypes WHERE RoleType = 'Manufacturer') AS RoleTypeIDTo,
	CURRENT_TIMESTAMP AS FromDate, 
	CONVERT(DATETIME, NULL) AS ThroughDate, 
	(SELECT PartyRelationshipTypeID FROM [$(SampleDB)].Party.PartyRelationshipTypes WHERE PartyRelationshipTypeName = 'Manufacturer Customer Relationship') AS PartyRelationshipTypeID,
	ISNULL(CustomerIdentifier, '') AS CustomerIdentifier, 
	CustomerIdentifierUsable, 
	CustomerIdentifierOriginatorPartyID
FROM dbo.VWT
WHERE ISNULL(MatchedODSPersonID, 0) = 0
AND ISNULL(ManufacturerID, 0) > 0
AND ISNULL(MatchedODSOrganisationID, 0) > 0
AND NULLIF(CustomerIdentifier, '') IS NOT NULL
