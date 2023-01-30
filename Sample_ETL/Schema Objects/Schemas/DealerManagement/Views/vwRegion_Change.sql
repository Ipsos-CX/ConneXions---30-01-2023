CREATE VIEW [DealerManagement].[vwRegion_Change]
AS 

/*
	Purpose:	Return Region Franchise update differences
	
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

		FL.[RDsRegion] AS RDsRegion_UPDATE,
		F.[RDsRegion] AS RDsRegion_ORIGINAL,
		FL.[BusinessRegion] AS BusinessRegion_UPDATE,
		F.[BusinessRegion] AS BusinessRegion_ORIGINAL,
		FL.[Region] AS Region_UPDATE,
		F.[Region] AS Region_ORIGINAL,
		FL.[RegionNumber] AS RegionNumber_UPDATE,
		F.[RegionNumber] AS RegionNumber_ORIGINAL		
	FROM DealerManagement.[Franchises_Load] FL
	INNER JOIN [Lookup].[FranchiseTypes_Questionnaire] FQ ON FL.FranchiseType = FQ.FranchiseType
	INNER JOIN [$(SampleDB)].[dbo].[Markets] M ON FL.FranchiseCountry = M.FranchiseCountry
	INNER JOIN [$(SampleDB)].[dbo].[vwBrandMarketQuestionnaireSampleMetadata] VW ON M.Market = VW.Market
																	     AND FQ.BMQQuestionnaire = VW.Questionnaire
																		 AND FL.Brand = VW.Brand 
	INNER JOIN [$(SampleDB)].[DealerManagement].[Franchises_Load] F ON FL.[10CharacterCode] = F.[10CharacterCode]
											   AND FL.FranchiseType = F.FranchiseType
											   AND FL.FranchiseCountry = F.FranchiseCountry
	WHERE CONCAT(FL.[RDsRegion], FL.[BusinessRegion], FL.[Region], FL.[RegionNumber])
	  <>  CONCAT(F.[RDsRegion], F.[BusinessRegion], F.[Region], F.[RegionNumber])