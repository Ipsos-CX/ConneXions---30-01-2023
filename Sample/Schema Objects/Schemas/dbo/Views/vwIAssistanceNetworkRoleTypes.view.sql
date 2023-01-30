CREATE VIEW [dbo].[vwIAssistanceNetworkRoleTypes]
AS
SELECT RoleTypeID
FROM dbo.RoleTypes 
WHERE RoleType IN ('I-Assistance Centre');