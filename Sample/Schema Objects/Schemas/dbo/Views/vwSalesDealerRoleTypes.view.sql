CREATE VIEW [dbo].[vwSalesDealerRoleTypes]
AS

SELECT RoleTypeID
FROM dbo.RoleTypes 
WHERE RoleType IN ('Authorised Dealer (Sales)')