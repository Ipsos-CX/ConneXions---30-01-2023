CREATE VIEW [dbo].[vwRoadsideNetworkRoleTypes]
AS
SELECT RoleTypeID
FROM dbo.RoleTypes 
WHERE RoleType IN ('Roadside Assistance Network');