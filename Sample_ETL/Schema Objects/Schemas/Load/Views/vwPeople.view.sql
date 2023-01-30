CREATE VIEW Load.vwPeople

AS

/*
	Purpose: View used to load People
	
	Version		Date			Developer			Comment
	1.1			2021-06-04		Chris Ledger		Task 472: Add UseLatestName		
*/

SELECT
	V.AuditItemID, 
	V.PersonParentAuditItemID AS ParentAuditItemID, 
	V.MatchedODSPersonID, 
	CURRENT_TIMESTAMP AS FromDate,
	V.TitleID, 
	ISNULL(V.Initials, '') AS Initials, 
	ISNULL(V.FirstName, '') AS FirstName, 
	ISNULL(V.MiddleName, '') AS MiddleName, 
	ISNULL(V.LastName, '') AS LastName , 
	ISNULL(V.SecondLastName, '') AS SecondLastName, 
	ISNULL(V.Title, '') AS Title, 
	ISNULL(V.FirstNameOrig, '') AS FirstNameOrig, 
	ISNULL(V.LastNameOrig, '') AS LastNameOrig, 
	ISNULL(V.SecondLastNameOrig, '') AS SecondLastNameOrig, 
	V.GenderID, 
	V.BirthDate,
	ISNULL(V.MonthAndYearOfBirth,'') AS MonthAndYearOfBirth,
    ISNULL(V.PreferredMethodOfContact,'') AS PreferredMethodOfContact,
	ISNULL(M.UseLatestName, 0) AS UseLatestName
FROM dbo.VWT V
	LEFT JOIN [$(SampleDB)].dbo.Markets M ON V.CountryID = M.CountryID
WHERE NULLIF(V.LastName, '') IS NOT NULL
	AND V.PersonParentAuditItemID > 0








