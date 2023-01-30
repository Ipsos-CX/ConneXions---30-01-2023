CREATE VIEW [Match].[vwRoadsideNetworks]
AS
SELECT
		N.PartyIDFrom AS RoadsideNetworkPartyID, 
		N.RoleTypeIDFrom, 
		N.PartyIDTo, 
		N.RoleTypeIDTo, 
		R.PartyRelationshipTypeID, 
		N.RoadsideNetworkCode
	FROM [$(SampleDB)].Party.RoadsideNetworks N
	JOIN [$(SampleDB)].Party.PartyRelationships R ON R.PartyIDFrom = N.PartyIDFrom
												AND R.RoleTypeIDFrom = N.RoleTypeIDFrom
												AND R.PartyIDTo = N.PartyIDTo
												AND R.RoleTypeIDTo = N.RoleTypeIDTo
	WHERE LTRIM(RTRIM(N.RoadsideNetworkCode)) <> N'';

