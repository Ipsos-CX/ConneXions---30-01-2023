CREATE VIEW [SelectionOutput].[vwInviteMatrixDealers]
	AS

	
/*

	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created
	1.1				2021-03-11		Chris Ledger		Replace OutletCode_GDD with OutletCode as we no longer collect OutletCode_GDD

*/

	--CLP DEALERS
	SELECT DISTINCT	D.TransferPartyID AS DealerID, 
		D.Manufacturer AS Brand, 
		C.Country, 
		CASE	WHEN D.OutletFunction ='Aftersales' THEN 'Service'
				ELSE D.OutletFunction
		END AS OutletFunction,
		D.OutletCode AS DealerCode,					-- V1.1
		DC.CountryID, 
		O.OrganisationName AS DealerName
	FROM dbo.DW_JLRCSPDealers D
		INNER JOIN ContactMechanism.DealerCountries DC ON D.TransferPartyID	= DC.PartyIDFrom 
														AND D.OutletFunctionID = DC.RoleTypeIDFrom
		INNER JOIN ContactMechanism.Countries C ON DC.CountryID = C.CountryID
		INNER JOIN		Party.Organisations O ON D.TransferPartyID = O.PartyID
	WHERE D.ThroughDate IS NULL 
		AND D.OutletCode IS NOT NULL				-- V1.1			
		AND	D.OutletCode NOT LIKE '%_BUG%'			-- V1.1
	UNION	-- CRC DEALERS
	SELECT CRC.PartyIDFrom,	
		CASE	WHEN CRC.PartyIDTo = 2 THEN 'Jaguar'
  				WHEN CRC.PartyIDTo = 3 THEN 'Land Rover'
		END AS Brand,
		C.Country, 
		'CRC' AS OutletFunction, 
		CRC.CRCCentreCode AS DealerCode, 
		CRC.CountryID, 
		CASE	WHEN CRC.PartyIDTo = 2 THEN 'Jaguar ' + CRC.CRCCentreCode + ' CRC Centre'
				WHEN CRC.PartyIDTo = 3 THEN 'Land Rover ' + CRC.CRCCentreCode + ' CRC Centre'
		END  AS DealerName
	FROM Party.CRCNetworks CRC
		INNER JOIN ContactMechanism.Countries C ON CRC.CountryID = C.CountryID
	UNION	--ROADSIDE DEALERS
	SELECT RN.PartyIDFrom,	
		CASE	WHEN RN.PartyIDTo = 2 THEN 'Jaguar'
  				WHEN RN.PartyIDTo = 3 THEN 'Land Rover'
		END AS Brand,
		C.Country, 
		'Roadside' AS OutletFunction,
		RN.RoadsideNetworkCode AS DealerCode, 
		RN.CountryID, 
		CASE	WHEN RN.PartyIDTo = 2 THEN 'Jaguar ' + RN.RoadsideNetworkCode + ' Roadside Centre'
				WHEN RN.PartyIDTo = 3 THEN 'Land Rover ' + RN.RoadsideNetworkCode + ' Roadside Centre'
		END  AS DealerName
	FROM Party.RoadsideNetworks RN
		INNER JOIN ContactMechanism.Countries C ON RN.CountryID = C.CountryID