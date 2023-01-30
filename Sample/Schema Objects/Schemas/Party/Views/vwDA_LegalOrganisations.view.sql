CREATE VIEW Party.vwDA_LegalOrganisations

AS

SELECT 
	CONVERT(BIGINT, 0) AS AuditItemID,
	CONVERT(BIGINT, 0) AS ParentAuditItemID,
	O.PartyID, 
	CONVERT(DATETIME2, NULL) AS FromDate, 
	O.OrganisationName,
	LO.LegalName,
	O.UseLatestName
FROM Party.Organisations O
INNER JOIN Party.LegalOrganisations LO ON LO.PartyID = O.PartyID





