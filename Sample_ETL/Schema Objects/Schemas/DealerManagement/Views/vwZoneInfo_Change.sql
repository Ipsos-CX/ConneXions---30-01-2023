CREATE VIEW [DealerManagement].[vwZoneInfo_Change]
AS 

/*
	Purpose:	Return Contact details Franchise update differences
	
	Version		Date		Deveoloper				Comment
	1.0			07/01/2021	Ben King     			Created

*/

	SELECT DISTINCT
		FL.[ImportAuditID],
		FL.[ImportAuditItemID],
		FL.[ImportFileName],
		FL.[10CharacterCode],
		FL.[Brand],
		FL.[FranchiseCountry],
		FL.[FranchiseType],
		FL.[FranchiseCICode],

		FL.[SalesZone] AS SalesZone_UPDATE,
		F.[SalesZone] AS SalesZone_ORIGINAL,
		FL.[SalesZoneCode] AS SalesZoneCode_UPDATE,
		F.[SalesZoneCode] AS SalesZoneCode_ORIGINAL,
		FL.[AuthorisedRepairerZone] AS AuthorisedRepairerZone_UPDATE,
		F.[AuthorisedRepairerZone] AS AuthorisedRepairerZone_ORIGINAL,
		FL.[AuthorisedRepairerZoneCode] AS AuthorisedRepairerZoneCode_UPDATE,
		F.[AuthorisedRepairerZoneCode] AS AuthorisedRepairerZoneCode_ORIGINAL,
		FL.[BodyshopZone] AS BodyshopZone_UPDATE,
		F.[BodyshopZone] AS BodyshopZone_ORIGINAL,
		FL.[BodyshopZoneCode] AS BodyshopZoneCode_UPDATE,
		F.[BodyshopZoneCode] AS BodyshopZoneCode_ORIGINAL

	FROM DealerManagement.[Franchises_Load] FL
	INNER JOIN [Lookup].[FranchiseTypes_Questionnaire] FQ ON FL.FranchiseType = FQ.FranchiseType
	INNER JOIN [$(SampleDB)].[dbo].[Markets] M ON FL.FranchiseCountry = M.FranchiseCountry
	INNER JOIN [$(SampleDB)].[dbo].[vwBrandMarketQuestionnaireSampleMetadata] VW ON M.Market = VW.Market
																	     AND FQ.BMQQuestionnaire = VW.Questionnaire
																		 AND FL.Brand = VW.Brand 
	INNER JOIN [$(SampleDB)].[DealerManagement].[Franchises_Load] F ON FL.[10CharacterCode] = F.[10CharacterCode]
											   AND FL.FranchiseType = F.FranchiseType
											   AND FL.FranchiseCountry = F.FranchiseCountry
	WHERE CONCAT(FL.[SalesZone], FL.[SalesZoneCode], FL.[AuthorisedRepairerZone], FL.[AuthorisedRepairerZoneCode], 
	             FL.[BodyshopZone], FL.[BodyshopZoneCode])
		  <>
		  CONCAT(F.[SalesZone], F.[SalesZoneCode], F.[AuthorisedRepairerZone], F.[AuthorisedRepairerZoneCode], 
	             F.[BodyshopZone], F.[BodyshopZoneCode])