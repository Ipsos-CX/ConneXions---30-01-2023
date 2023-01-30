CREATE VIEW [Match].[vwIAssistanceNetworks]
AS
SELECT
		N.PartyIDFrom AS IAssistanceCentrePartyID, 
		N.RoleTypeIDFrom, 
		N.PartyIDTo, 
		N.RoleTypeIDTo, 
		R.PartyRelationshipTypeID, 
		N.IAssistanceCentreCode
	FROM [$(SampleDB)].Party.IAssistanceNetworks N
	JOIN [$(SampleDB)].Party.PartyRelationships R ON R.PartyIDFrom = N.PartyIDFrom
												AND R.RoleTypeIDFrom = N.RoleTypeIDFrom
												AND R.PartyIDTo = N.PartyIDTo
												AND R.RoleTypeIDTo = N.RoleTypeIDTo
	WHERE LTRIM(RTRIM(N.IAssistanceCentreCode)) <> N'';

