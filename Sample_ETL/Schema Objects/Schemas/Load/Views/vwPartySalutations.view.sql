CREATE VIEW Load.vwPartySalutations
AS

-- ORGANISATIONS
SELECT
	AuditItemID, 
	MatchedODSOrganisationID AS PartyID, 
	Salutation
FROM dbo.VWT
WHERE MatchedODSOrganisationID > 0
AND ISNULL(MatchedODSPersonID, 0) = 0
AND ISNULL(LTRIM(RTRIM(Salutation)), N'') <> ''

UNION 

-- PEOPLE
SELECT
	AuditItemID, 
	MatchedODSPersonID, 
	Salutation
FROM dbo.VWT
WHERE MatchedODSPersonID > 0
AND ISNULL(LTRIM(RTRIM(Salutation)), N'') <> ''

UNION

-- PARTIES
SELECT
	AuditItemID, 
	MatchedODSPartyID, 
	Salutation
FROM dbo.VWT
WHERE MatchedODSPartyID > 0
AND ISNULL(MatchedODSPersonID, 0) = 0
AND ISNULL(MatchedODSOrganisationID, 0) = 0
AND ISNULL(LTRIM(RTRIM(Salutation)), N'') <> ''











