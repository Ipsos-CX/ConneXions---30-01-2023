CREATE VIEW [DealerManagement].[vwRetailerLocality_Change]
AS 

/*
	Purpose:	Return Retailer Locality Franchise update differences
	
	Version		Date		Deveoloper				Comment
	1.0			13/08/2021	Ben King     			TASK 577 - PAGName to be filled in using FIMs Retailer Locality field

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

	
		FL.[RetailerLocality] AS RetailerLocality_UPDATE,
		F.[RetailerLocality] AS RetailerLocality_ORIGINAL

	FROM DealerManagement.[Franchises_Load] FL
	INNER JOIN [Lookup].[FranchiseTypes_Questionnaire] FQ ON FL.FranchiseType = FQ.FranchiseType
	INNER JOIN [$(SampleDB)].[dbo].[Markets] M ON FL.FranchiseCountry = M.FranchiseCountry
	INNER JOIN [$(SampleDB)].[dbo].[vwBrandMarketQuestionnaireSampleMetadata] VW ON M.Market = VW.Market
																	     AND FQ.BMQQuestionnaire = VW.Questionnaire
																		 AND FL.Brand = VW.Brand 
	INNER JOIN [$(SampleDB)].[DealerManagement].[Franchises_Load] F ON FL.[10CharacterCode] = F.[10CharacterCode]
											   AND FL.FranchiseType = F.FranchiseType
											   AND FL.FranchiseCountry = F.FranchiseCountry
	WHERE FL.[RetailerLocality]
	  <>  F.[RetailerLocality]

GO