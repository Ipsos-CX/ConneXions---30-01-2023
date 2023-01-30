CREATE VIEW [Match].[vwCQIDealers]
AS

/*
		Purpose:	Returns all dealer / manufacturer associations with codes for matching against dealer codes in VWT for CQI
	
		Version		Date			Developer			Comment
LIVE	1.0			2021-04-09		Chris Ledger		TASK 1049 - Created from vwDealers view to include Terminated Dealers for CQI

*/
	SELECT
		DN.PartyIDFrom AS DealerID, 
		DN.RoleTypeIDFrom, 
		DN.PartyIDTo, 
		DN.RoleTypeIDTo, 
		PR.PartyRelationshipTypeID, 
		DN.DealerCode,
		CASE	WHEN C.Country = 'Luxembourg' THEN (SELECT CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'Belgium')
				ELSE DC.CountryID END AS CountryID
	FROM [$(SampleDB)].Party.DealerNetworks DN
	INNER JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON DN.PartyIDFrom = D.OutletPartyID
													AND DN.RoleTypeIDFrom = D.OutletFunctionID
	JOIN [$(SampleDB)].Party.PartyRelationships PR ON PR.PartyIDFrom = DN.PartyIDFrom
												AND PR.RoleTypeIDFrom = DN.RoleTypeIDFrom
												AND PR.PartyIDTo = DN.PartyIDTo
												AND PR.RoleTypeIDTo = DN.RoleTypeIDTo
	LEFT JOIN [$(SampleDB)].ContactMechanism.DealerCountries DC ON DC.PartyIDFrom = DN.PartyIDFrom
												AND DC.RoleTypeIDFrom = DN.RoleTypeIDFrom
												AND DC.PartyIDTo = DN.PartyIDTo
												AND DC.RoleTypeIDTo = DN.RoleTypeIDTo
												AND DC.DealerCode = DN.DealerCode
	LEFT JOIN [$(SampleDB)].ContactMechanism.Countries C ON DC.CountryID = C.CountryID
	WHERE LTRIM(RTRIM(DN.DealerCode)) <> N''
		AND ISNULL(D.ThroughDate,'2099-01-01') >= DATEADD(DD,-790, GETDATE())	-- V1.0 Only include dealers terminated in last 2 years (adjusted to match CQI selection window)



