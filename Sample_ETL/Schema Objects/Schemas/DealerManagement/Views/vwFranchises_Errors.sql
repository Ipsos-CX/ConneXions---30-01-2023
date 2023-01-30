CREATE VIEW [DealerManagement].[vwFranchises_Errors]
AS 

/*
	Purpose:	Return data failed validation checks
	
	Version		Date		Deveoloper				Comment
	1.0			26/01/2021	Ben King     			BUG 18055

*/

	SELECT DISTINCT
		H.[IP_DataError],
		H.[AuditID],
		H.[AuditItemID],
		H.[RDsRegion],
		H.[BusinessRegion],
		H.[DistributorCountryCode],
		H.[DistributorCountry],
		H.[DistributorCICode],
		H.[DistributorName],
		H.[FranchiseCountryCode],
		H.[FranchiseCountry],
		H.[JLRNumber],
		H.[RetailerLocality],
		H.[Brand],
		H.[FranchiseCICode],
		H.[FranchiseTradingTitle],
		H.[FranchiseShortName],
		H.[RetailerGroup],
		H.[FranchiseType],
		H.[Address1],
		H.[Address2],
		H.[Address3],
		H.[AddressTown],
		H.[AddressCountyDistrict],
		H.[AddressPostcode],
		H.[AddressLatitude],
		H.[AddressLongitude],
		H.[AddressActivity],
		H.[Telephone],
		H.[Email],
		H.[URL],
		H.[FranchiseStatus],
		H.[FranchiseStartDate],
		H.[FranchiseEndDate],
		H.[LegacyFlag],
		H.[10CharacterCode],
		H.[FleetandBusinessRetailer],
		H.[SVO],
		H.[Market],
		H.[MarketNumber],
		H.[Region],
		H.[RegionNumber],
		H.[SalesZone],
		H.[SalesZoneCode],
		H.[AuthorisedRepairerZone],
		H.[AuthorisedRepairerZoneCode],
		H.[BodyshopZone],
		H.[BodyshopZoneCode],
		H.[LocalTradingTitle1],
		H.[LocalLanguage1],
		H.[LocalTradingTitle2],
		H.[LocalLanguage2]
	FROM Stage.Franchise_Hierarchy H
	WHERE IP_DataError IS NOT NULL
	



GO