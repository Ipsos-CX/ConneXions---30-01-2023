CREATE VIEW Load.vwLegalOrganisations

AS

/*
	Purpose: View used to load organisations
	
	Version		Date			Developer			Comment
	1.1			2021-06-04		Chris Ledger		Task 472: Add UseLatestName		
*/

	SELECT
		V.AuditItemID, 
		V.OrganisationParentAuditItemID AS ParentAuditItemID, 
		V.MatchedODSOrganisationID, 
		CURRENT_TIMESTAMP AS FromDate, 
		ISNULL(V.OrganisationName, '') AS OrganisationName, 
		ISNULL(V.OrganisationName, '') AS LegalName,
		ISNULL(M.UseLatestName, 0) AS UseLatestName
	FROM dbo.VWT V
		LEFT JOIN [$(SampleDB)].dbo.Markets M ON V.CountryID = M.CountryID
	WHERE NULLIF(V.OrganisationName, '') IS NOT NULL










