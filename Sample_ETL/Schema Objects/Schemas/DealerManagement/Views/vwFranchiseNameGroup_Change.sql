CREATE VIEW [DealerManagement].[vwFranchiseNameGroup_Change]
AS 

/*
	Purpose:	Return Franchise Name and Group Franchise update differences
	
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

		FL.[FranchiseTradingTitle] AS FranchiseTradingTitle_UPDATE,
		F.[FranchiseTradingTitle] AS FranchiseTradingTitle_ORIGINAL,
		FL.[RetailerGroup] AS RetailerGroup_UPDATE,
		F.[RetailerGroup] AS RetailerGroup_ORIGINAL

	FROM DealerManagement.[Franchises_Load] FL
	INNER JOIN [Lookup].[FranchiseTypes_Questionnaire] FQ ON FL.FranchiseType = FQ.FranchiseType
	INNER JOIN [$(SampleDB)].[dbo].[Markets] M ON FL.FranchiseCountry = M.FranchiseCountry
	INNER JOIN [$(SampleDB)].[dbo].[vwBrandMarketQuestionnaireSampleMetadata] VW ON M.Market = VW.Market
																	     AND FQ.BMQQuestionnaire = VW.Questionnaire
																		 AND FL.Brand = VW.Brand 
	INNER JOIN [$(SampleDB)].[DealerManagement].[Franchises_Load] F ON FL.[10CharacterCode] = F.[10CharacterCode]
											   AND FL.FranchiseType = F.FranchiseType
											   AND FL.FranchiseCountry = F.FranchiseCountry
	WHERE CONCAT(FL.[FranchiseTradingTitle], FL.[RetailerGroup])
	  <>  CONCAT(F.[FranchiseTradingTitle], F.[RetailerGroup])