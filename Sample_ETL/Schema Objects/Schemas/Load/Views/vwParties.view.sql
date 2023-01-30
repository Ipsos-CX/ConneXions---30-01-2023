CREATE VIEW Load.vwParties

AS

	SELECT
		AuditItemID, 
		MatchedODSPartyID, 
		CURRENT_TIMESTAMP AS FromDate,
		(SELECT RoleTypeID FROM [$(SampleDB)].dbo.RoleTypes WHERE RoleType = 'Customer') AS RoleTypeID
	FROM dbo.VWT
	WHERE ISNULL(MatchedODSPartyID, 0) = 0
	AND NULLIF(LTRIM(RTRIM(LastName)), '') IS NULL
	AND NULLIF(LTRIM(RTRIM(OrganisationName)), '') IS NULL
