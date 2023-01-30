CREATE VIEW Load.vwIndustryClassifications

AS


/*
	Purpose:	Used to set industry classification
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Original version
	1.1				13/06/2013		Chris Ross			BUG 8969 - Use new field in VWT: SuppliedIndustryClassificationID (set from 
														TypeOfSale flag) to also set the industry classification.  Note: it is not just set 
														on Organisation but in individual if there is no Org attached.
	1.2				16/10/2015		Chris Ross			BUG 11933 - Add in country specific Classification functionality.  Where a country Exists then 
																	the BlackList string is for that country only, otherwise it is global.
	1.3				09/12/2019		Chris Ross			BUG 16810 - Lookup and return PartyExclusionCategoryID (also includes lookup of default, if supplied via VWT).
													
*/
-- Global Blacklist strings first (i.e. not Country Specific)
SELECT
	V.AuditItemID,
	BIC.PartyTypeID,
	O.PartyID,
	GETDATE() AS FromDate,
	CAST(NULL AS DATETIME2) AS ThroughDate,
	BIC.PartyExclusionCategoryID					-- v1.3
FROM [$(SampleDB)].Party.Organisations O
INNER JOIN [$(SampleDB)].Party.BlacklistStrings B ON O.OrganisationName LIKE B.BlacklistString
INNER JOIN [$(SampleDB)].Party.BlacklistIndustryClassifications BIC ON BIC.BlacklistStringID = B.BlacklistStringID
INNER JOIN dbo.VWT V ON V.MatchedODSOrganisationID = O.PartyID
WHERE NOT EXISTS (SELECT BCC.BlacklistStringID FROM [$(SampleDB)].Party.BlacklistIndustryClassificationsCountry BCC 
													  WHERE BCC.BlacklistStringID = B.BlacklistStringID)

UNION

-- Country Specific Blacklist strings 
SELECT
	V.AuditItemID,
	BIC.PartyTypeID,
	O.PartyID,
	GETDATE() AS FromDate,
	CAST(NULL AS DATETIME2) AS ThroughDate,
	BIC.PartyExclusionCategoryID					-- v1.3
FROM [$(SampleDB)].Party.Organisations O
INNER JOIN [$(SampleDB)].Party.BlacklistStrings B ON O.OrganisationName LIKE B.BlacklistString
INNER JOIN [$(SampleDB)].Party.BlacklistIndustryClassifications BIC ON BIC.BlacklistStringID = B.BlacklistStringID
INNER JOIN dbo.VWT V ON V.MatchedODSOrganisationID = O.PartyID
INNER JOIN [$(SampleDB)].Party.BlacklistIndustryClassificationsCountry BCC ON BCC.BlacklistStringID = B.BlacklistStringID	
																	 AND BCC.CountryID = V.CountryID	-- Only apply where Country Matches

UNION

-- Sample Supplied BlackList Strings
SELECT
	V.AuditItemID,
	V.SuppliedIndustryClassificationID AS PartyTypeID,
	COALESCE( NULLIF(MatchedODSOrganisationID, 0), NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSPartyID, 0) ) AS PartyID,
	GETDATE() AS FromDate,
	CAST(NULL AS DATETIME2) AS ThroughDate,
	pt.DefaultPartyExclusionCategoryID AS PartyExclusionCategoryID			-- v1.3
FROM dbo.VWT V 
INNER JOIN [$(SampleDB)].Party.PartyTypes pt ON pt.PartyTypeID = V.SuppliedIndustryClassificationID
WHERE ISNULL (V.SuppliedIndustryClassificationID, 0) <> 0
AND COALESCE( NULLIF(MatchedODSOrganisationID, 0), NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSPartyID, 0) ) IS NOT NULL;



