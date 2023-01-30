CREATE VIEW [dbo].[vwDealerRoleTypes]
AS

/* 
		Purpose:	Get Dealer Role Types for CaseDetails Dealer update
	
		Version		Date			Developer			Comment										
LIVE	1.1			2022-08-22		Chris Ledger		Task 1002 - add Authorised Experience Centre

*/

SELECT RoleTypeID
FROM dbo.RoleTypes 
WHERE RoleType IN ('Authorised Dealer (Sales)', 'Authorised Dealer (Aftersales)', 'Authorised Dealer (PreOwned)','Authorised Dealer (BodyShop)','Authorised Experience Centre')	-- V1.1