CREATE VIEW Load.vwPartyNonSolicitations

AS

SELECT     
	V.AuditItemID, 
	0 AS NonSolicitationID,
	7 AS NonSolicitationTextID, 
	O.PartyID, 
	NULL AS RoleTypeID, 
	GETDATE() AS FromDate, 
	CAST(NULL AS DATETIME2) AS ThroughDate, 
	NULL AS Notes
FROM [$(SampleDB)].Party.Organisations O 
INNER JOIN [$(SampleDB)].Party.BlacklistStrings B ON O.OrganisationName = B.BlacklistString 
INNER JOIN [$(SampleDB)].Party.BlacklistStringNonSolicitations BNS ON BNS.BlacklistStringID = B.BlacklistStringID 
INNER JOIN dbo.VWT V ON V.MatchedODSOrganisationID = O.PartyID

UNION

SELECT     
	V.AuditItemID, 
	0 AS NonSolicitationID,	
	7 AS NonSolicitationTextID, 
	P.PartyID, 
	NULL AS RoleTypeID, 
	GETDATE() AS FromDate, 
	CAST(NULL AS DATETIME2) AS ThroughDate, 
	NULL AS Notes
FROM [$(SampleDB)].Party.People P 
INNER JOIN [$(SampleDB)].Party.Titles T ON T.TitleID = P.TitleID 
INNER JOIN [$(SampleDB)].Party.BlacklistStrings B ON (T.Title + ' ' + P.FirstName + ' ' + P.LastName + ' ' + P.SecondLastName) = B.BlacklistString 
INNER JOIN [$(SampleDB)].Party.BlacklistStringNonSolicitations BNS ON BNS.BlacklistStringID = B.BlacklistStringID 
INNER JOIN dbo.VWT V ON V.MatchedODSPersonID = P.PartyID

