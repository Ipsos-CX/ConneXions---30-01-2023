CREATE VIEW Party.vwDA_IndustryClassifications

AS

SELECT
	CONVERT(BIGINT, 0) AS AuditItemID, 
	PT.PartyTypeID, 
	PC.PartyID, 
	PC.FromDate, 
	CONVERT(DATETIME2, NULL) AS ThroughDate,		
	IC.PartyExclusionCategoryID		-- v1.1
FROM Party.IndustryClassifications IC
INNER JOIN Party.PartyClassifications PC ON IC.PartyTypeID = PC.PartyTypeID
										AND IC.PartyID = PC.PartyID
INNER JOIN Party.PartyTypes PT ON PT.PartyTypeID = PC.PartyTypeID
INNER JOIN Party.PartyExclusionCategories PEC ON PEC.PartyExclusionCategoryID = IC.PartyExclusionCategoryID
