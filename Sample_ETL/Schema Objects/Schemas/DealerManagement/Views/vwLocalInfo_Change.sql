CREATE VIEW [DealerManagement].[vwLocalInfo_Change]
AS 

/*
	Purpose:	Return Local Info Franchise update differences
	
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

		FL.[LocalTradingTitle1] AS LocalTradingTitle1_UPDATE,
		F.[LocalTradingTitle1] AS LocalTradingTitle1_ORIGINAL,
		FL.[LocalLanguage1] AS LocalLanguage1_UPDATE,
		F.[LocalLanguage1] AS LocalLanguage1_ORIGINAL,
		FL.[LocalTradingTitle2] AS LocalTradingTitle2_UPDATE,
		F.[LocalTradingTitle2] AS LocalTradingTitle2_ORIGINAL,
		FL.[LocalLanguage2] AS LocalLanguage2_UPDATE,
		F.[LocalLanguage2] AS LocalLanguage2_ORIGINAL

	FROM DealerManagement.[Franchises_Load] FL
	INNER JOIN [Lookup].[FranchiseTypes_Questionnaire] FQ ON FL.FranchiseType = FQ.FranchiseType
	INNER JOIN [$(SampleDB)].[dbo].[Markets] M ON FL.FranchiseCountry = M.FranchiseCountry
	INNER JOIN [$(SampleDB)].[dbo].[vwBrandMarketQuestionnaireSampleMetadata] VW ON M.Market = VW.Market
																	     AND FQ.BMQQuestionnaire = VW.Questionnaire
																		 AND FL.Brand = VW.Brand 
	INNER JOIN [$(SampleDB)].[DealerManagement].[Franchises_Load] F ON FL.[10CharacterCode] = F.[10CharacterCode]
											   AND FL.FranchiseType = F.FranchiseType
											   AND FL.FranchiseCountry = F.FranchiseCountry
	WHERE CONCAT(FL.[LocalTradingTitle1], FL.[LocalLanguage1], FL.[LocalTradingTitle2], FL.[LocalLanguage2])
	  <>  CONCAT(F.[LocalTradingTitle1], F.[LocalLanguage1], F.[LocalTradingTitle2], F.[LocalLanguage2])
	

