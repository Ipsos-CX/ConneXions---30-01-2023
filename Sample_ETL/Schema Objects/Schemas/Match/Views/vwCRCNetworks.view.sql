CREATE VIEW [Match].[vwCRCNetworks]
AS

SELECT
		N.PartyIDFrom AS CRCCentrePartyID, 
		N.RoleTypeIDFrom, 
		N.PartyIDTo, 
		N.RoleTypeIDTo, 
		R.PartyRelationshipTypeID, 
		N.CRCCentreCode
	FROM [$(SampleDB)].Party.CRCNetworks N
	JOIN [$(SampleDB)].Party.PartyRelationships R ON R.PartyIDFrom = N.PartyIDFrom
												AND R.RoleTypeIDFrom = N.RoleTypeIDFrom
												AND R.PartyIDTo = N.PartyIDTo
												AND R.RoleTypeIDTo = N.RoleTypeIDTo
	WHERE LTRIM(RTRIM(N.CRCCentreCode)) <> N'';

