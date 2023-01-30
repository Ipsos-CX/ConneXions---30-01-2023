CREATE VIEW [dbo].[vwServiceDealerRoleTypes]
AS

SELECT RoleTypeID
FROM dbo.RoleTypes 
WHERE RoleType IN ('Authorised Dealer (Aftersales)')