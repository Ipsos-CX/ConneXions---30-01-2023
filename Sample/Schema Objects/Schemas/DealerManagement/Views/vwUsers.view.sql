CREATE VIEW [DealerManagement].[vwUsers]

AS


	--	Purpose:	Pass back a list of all users who are permitted to play the 'DealerManagement' role
	--				In addition pass back the UserName for their OWAP account also so we have something 
	--				to validate when checking user permissions.
	--	
	--	
	--	Version		Developer			Date			Comment	
	--	1.0			Martin Riverol		20/04/2012		Created
	

	SELECT
		P.PartyID
		, 
			ISNULL(NULLIF(P.FirstName + ' ', ' '), '') + 
			ISNULL(NULLIF(P.LastName + ' ', ' '), '') + 
			ISNULL(P.SecondLastName, '') AS UserFullName
		, RT.RoleTypeID 
		, RT.RoleType 
		, PR.PartyRoleID
		, OU.UserName
	FROM DealerManagement.RoleTypes DMRT
	INNER JOIN dbo.RoleTypes RT ON DMRT.RoleTypeID = RT.RoleTypeID
	INNER JOIN Party.PartyRoles pr on rt.RoleTypeID = pr.RoleTypeID
	INNER JOIN Party.People P ON Pr.PartyID = p.PartyID
	INNER JOIN Party.Titles T ON T.TitleID = P.TitleID
	INNER JOIN OWAP.vwUsers OU ON P.PartyID = OU.PartyID