CREATE VIEW Party.vwDA_PartyClassifications

AS

SELECT
	CONVERT(BIGINT, 0) AS AuditItemID, 
	PT.PartyTypeID, 
	PC.PartyID, 
	PC.FromDate, 
	CONVERT(DATETIME2, NULL) AS ThroughDate
FROM Party.PartyClassifications PC
INNER JOIN Party.PartyTypes PT ON PT.PartyTypeID = PC.PartyTypeID


