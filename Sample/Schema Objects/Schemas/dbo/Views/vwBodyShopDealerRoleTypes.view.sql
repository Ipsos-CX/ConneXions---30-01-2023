CREATE VIEW [dbo].[vwBodyshopDealerRoleTypes]
AS 

SELECT RoleTypeID
FROM dbo.RoleTypes 
WHERE RoleType IN ('Authorised Dealer (Bodyshop)')