CREATE VIEW [DealerManagement].[vwFleetSVOflags_Change]
AS 

/*
	Purpose:	Return Fleet & SVO Flags Franchise update differences
	
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

		FL.[FleetandBusinessRetailer] AS FleetandBusinessRetailer_UPDATE,
		F.[FleetandBusinessRetailer] AS FleetandBusinessRetailer_ORIGINAL,
		FL.[SVO] AS SVO_UPDATE,
		F.[SVO] AS SVO_ORIGINAL

	FROM DealerManagement.[Franchises_Load] FL
	INNER JOIN [Lookup].[FranchiseTypes_Questionnaire] FQ ON FL.FranchiseType = FQ.FranchiseType
	INNER JOIN [$(SampleDB)].[dbo].[Markets] M ON FL.FranchiseCountry = M.FranchiseCountry
	INNER JOIN [$(SampleDB)].[dbo].[vwBrandMarketQuestionnaireSampleMetadata] VW ON M.Market = VW.Market
																	     AND FQ.BMQQuestionnaire = VW.Questionnaire
																		 AND FL.Brand = VW.Brand 
	INNER JOIN [$(SampleDB)].[DealerManagement].[Franchises_Load] F ON FL.[10CharacterCode] = F.[10CharacterCode]
											   AND FL.FranchiseType = F.FranchiseType
											   AND FL.FranchiseCountry = F.FranchiseCountry
	WHERE CONCAT(FL.[FleetandBusinessRetailer], FL.[SVO])
	  <>  CONCAT(F.[FleetandBusinessRetailer], F.[SVO])
