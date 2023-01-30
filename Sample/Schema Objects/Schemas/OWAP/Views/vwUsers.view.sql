CREATE VIEW [OWAP].[vwUsers]
AS
SELECT
	U.PartyID, 
	ISNULL(NULLIF(P.FirstName + ' ', ' '), '') + ISNULL(NULLIF(P.LastName + ' ', ' '), '') + ISNULL(P.SecondLastName, '') AS UserFullName, 
	RT.RoleTypeID, 
	RT.RoleType, 
	U.UserName, 
	U.[Password],
	PR.PartyRoleID
FROM OWAP.Users U
INNER JOIN Party.PartyRoles PR ON U.PartyID = PR.PartyID
						AND U.RoleTypeID = PR.RoleTypeID
INNER JOIN OWAP.RoleTypes ORT ON ORT.RoleTypeID = PR.RoleTypeID
INNER JOIN dbo.RoleTypes RT ON ORT.RoleTypeID = RT.RoleTypeID
INNER JOIN Party.People P ON P.PartyID = U.PartyID
INNER JOIN Party.Titles T ON T.TitleID = P.TitleID

