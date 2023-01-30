CREATE VIEW Party.vwDA_People
AS

SELECT
	CONVERT(BIGINT, 0) AS ParentAuditItemID, 
	CONVERT(BIGINT, 0) AS AuditItemID,
	P.PartyID, 
	P.FromDate,
	P.TitleID,
	T.Title, 
	P.Initials, 
	P.FirstName, 
	P.MiddleName, 
	P.LastName, 
	P.SecondLastName, 
	CONVERT(NVARCHAR(100), '') AS FirstNameOrig, 
	CONVERT(NVARCHAR(100), '') AS LastNameOrig, 
	CONVERT(NVARCHAR(100), '') AS SecondLastNameOrig, 
	P.GenderID, 
	P.BirthDate,
	P.MonthAndYearOfBirth,
	P.PreferredMethodOfContact,
	P.UseLatestName
FROM Party.People P
INNER JOIN Party.Titles T ON T.TitleID = P.TitleID












