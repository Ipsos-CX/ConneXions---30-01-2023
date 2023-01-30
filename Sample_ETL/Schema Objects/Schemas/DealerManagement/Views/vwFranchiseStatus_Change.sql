CREATE VIEW [DealerManagement].[vwFranchiseStatus_Change]
AS 

/*
	Purpose:	Return Franchise Status Franchise update differences
	
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

		FL.[FranchiseStatus] AS FranchiseStatus_UPDATE,
		F.[FranchiseStatus] AS FranchiseStatus_ORIGINAL,
		FL.[FranchiseStartDate] AS FranchiseStartDate_UPDATE,
		F.[FranchiseStartDate] AS FranchiseStartDate_ORIGINAL,
		FL.[FranchiseEndDate] AS FranchiseEndDate_UPDATE,
		F.[FranchiseEndDate] AS FranchiseEndDate_ORIGINAL

	FROM DealerManagement.[Franchises_Load] FL
	INNER JOIN [Lookup].[FranchiseTypes_Questionnaire] FQ ON FL.FranchiseType = FQ.FranchiseType
	INNER JOIN [$(SampleDB)].[dbo].[Markets] M ON FL.FranchiseCountry = M.FranchiseCountry
	INNER JOIN [$(SampleDB)].[dbo].[vwBrandMarketQuestionnaireSampleMetadata] VW ON M.Market = VW.Market
																	     AND FQ.BMQQuestionnaire = VW.Questionnaire
																		 AND FL.Brand = VW.Brand 
	INNER JOIN [$(SampleDB)].[DealerManagement].[Franchises_Load] F ON FL.[10CharacterCode] = F.[10CharacterCode]
											   AND FL.FranchiseType = F.FranchiseType
											   AND FL.FranchiseCountry = F.FranchiseCountry
	WHERE CONCAT(FL.[FranchiseStatus], FL.[FranchiseStartDate], FL.[FranchiseEndDate])
	  <>  CONCAT(F.[FranchiseStatus], F.[FranchiseStartDate], F.[FranchiseEndDate])