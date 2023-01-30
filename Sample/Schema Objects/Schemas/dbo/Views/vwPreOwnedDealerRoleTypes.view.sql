CREATE VIEW [dbo].[vwPreOwnedDealerRoleTypes]
AS

SELECT RoleTypeID
FROM dbo.RoleTypes 
WHERE RoleType IN ('Authorised Dealer (PreOwned)')