CREATE VIEW [DealerManagement].[vwFranchises_New]
AS 

/*
	Purpose:	Return data to be fed into the Echo system
	
	Version		Date		Deveoloper				Comment
	1.0			07/01/2021	Ben King     			Created

*/
	SELECT DISTINCT
		FL.[ImportAuditID],
		FL.[ImportAuditItemID],
		FL.[ImportFileName],
		FL.[RDsRegion],
		FL.[BusinessRegion],
		FL.[DistributorCountryCode],
		FL.[DistributorCountry],
		FL.[DistributorCICode],
		FL.[DistributorName],
		FL.[FranchiseCountryCode],
		FL.[FranchiseCountry],
		FL.[JLRNumber],
		FL.[RetailerLocality],
		FL.[Brand],
		FL.[FranchiseCICode],
		FL.[FranchiseTradingTitle],
		FL.[FranchiseShortName],
		FL.[RetailerGroup],
		FL.[FranchiseType],
		FL.[Address1],
		FL.[Address2],
		FL.[Address3],
		FL.[AddressTown],
		FL.[AddressCountyDistrict],
		FL.[AddressPostcode],
		FL.[AddressLatitude],
		FL.[AddressLongitude],
		FL.[AddressActivity],
		FL.[Telephone],
		FL.[Email],
		FL.[URL],
		FL.[FranchiseStatus],
		FL.[FranchiseStartDate],
		FL.[FranchiseEndDate],
		FL.[LegacyFlag],
		FL.[10CharacterCode],
		FL.[FleetandBusinessRetailer],
		FL.[SVO],
		FL.[Market],
		FL.[MarketNumber],
		FL.[Region],
		FL.[RegionNumber],
		FL.[SalesZone],
		FL.[SalesZoneCode],
		FL.[AuthorisedRepairerZone],
		FL.[AuthorisedRepairerZoneCode],
		FL.[BodyshopZone],
		FL.[BodyshopZoneCode],
		FL.[LocalTradingTitle1],
		FL.[LocalLanguage1],
		FL.[LocalTradingTitle2],
		FL.[LocalLanguage2]
	FROM DealerManagement.[Franchises_Load] FL
	INNER JOIN [Lookup].[FranchiseTypes_Questionnaire] FQ ON FL.FranchiseType = FQ.FranchiseType
	INNER JOIN [$(SampleDB)].[dbo].[Markets] M ON FL.FranchiseCountry = M.FranchiseCountry
	INNER JOIN [$(SampleDB)].[dbo].[vwBrandMarketQuestionnaireSampleMetadata] VW ON M.Market = VW.Market
																	     AND FQ.BMQQuestionnaire = VW.Questionnaire
																		 AND FL.Brand = VW.Brand 
	LEFT JOIN [$(SampleDB)].[DealerManagement].[Franchises_Load] F ON FL.[10CharacterCode] = F.[10CharacterCode]
											   AND FL.FranchiseType = F.FranchiseType
											   AND FL.FranchiseCountry = F.FranchiseCountry
	WHERE F.[10CharacterCode] IS NULL
	