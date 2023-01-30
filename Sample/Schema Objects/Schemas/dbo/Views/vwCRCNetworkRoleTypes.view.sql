CREATE VIEW [dbo].[vwCRCNetworkRoleTypes]
AS
SELECT RoleTypeID
FROM dbo.RoleTypes 
WHERE RoleType IN ('CRC Centre');
