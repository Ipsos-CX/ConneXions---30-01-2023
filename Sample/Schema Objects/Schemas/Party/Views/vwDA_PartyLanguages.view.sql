CREATE VIEW Party.vwDA_PartyLanguages

AS

SELECT
	CONVERT(BIGINT, 0) AS AuditItemID, 
	PartyID, 
	LanguageID, 
	CONVERT(DATETIME2, NULL) AS FromDate, 
	CONVERT(DATETIME2, NULL) AS ThroughDate, 
	PreferredFlag
FROM Party.PartyLanguages



