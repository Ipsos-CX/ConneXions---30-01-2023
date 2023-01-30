CREATE VIEW [dbo].[vwExperienceDealerRoleTypes]
AS
SELECT RoleTypeID
FROM dbo.RoleTypes 
WHERE RoleType IN ('Authorised Experience Centre')