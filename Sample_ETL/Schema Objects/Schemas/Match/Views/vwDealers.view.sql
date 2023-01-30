CREATE VIEW [Match].[vwDealers]
AS

/*
	Purpose:	Returns all dealer / manufacturer associations with codes for matching against dealer codes in VWT
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created from [Prophet-ETL].dbo.vwAUDIT_Dealers
	1.1				2021-02-03		Chris Ledger		TASK 249 - Use Belgium as Country for Luxembourg to match previous logic
	1.2				2021-04-09		Chris Ledger		TASK 381 - Exclude Terminated Dealers

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
	INNER JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON DN.PartyIDFrom = D.OutletPartyID				-- V1.2
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
	AND D.ThroughDate IS NULL																		-- V1.2



