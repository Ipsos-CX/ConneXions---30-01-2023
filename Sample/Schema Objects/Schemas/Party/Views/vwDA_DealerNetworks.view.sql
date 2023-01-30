CREATE VIEW [Party].[vwDA_DealerNetworks]

AS

	--
	--	Purpose:	Data Access view to enable to writing of Dealer PartyRelationshipds into the sample model
	--
	--
	--	Version		Developer			Date			Comment
	--	1.0			Martin Riverol		24/04/2012		Created
	--
	
	SELECT 
		CONVERT(BIGINT, 0) AS AuditItemID 
		, DN.PartyIDFrom 
		, DN.PartyIDTo 
		, DN.RoleTypeIDFrom 
		, DN.RoleTypeIDTo 
		, DN.DealerCode 
		, DN.DealerShortName 
		, PR.FromDate 
		, CONVERT(DATETIME, NULL) AS ThroughDate 
		, PR.PartyRelationshipTypeID
	FROM Party.DealerNetworks AS DN
	INNER JOIN Party.PartyRelationships AS PR ON DN.PartyIDFrom = PR.PartyIDFrom
													AND DN.PartyIDTo = PR.PartyIDTo
													AND DN.RoleTypeIDFrom = PR.RoleTypeIDFrom
													AND DN.RoleTypeIDTo = PR.RoleTypeIDTo