CREATE VIEW Party.vwDA_LegalOrganisationsByLanguage

AS

SELECT 
	CONVERT(BIGINT, 0) AS AuditItemID,
	CONVERT(BIGINT, 0) AS ParentAuditItemID,
	O.PartyID, 
	CONVERT(DATETIME2, NULL) AS FromDate, 
	O.OrganisationName, 
	LOL.LegalName,
	LOL.LanguageID,
	O.UseLatestName
FROM Party.Organisations O
INNER JOIN Party.LegalOrganisationsByLanguage LOL ON LOL.PartyID = O.PartyID