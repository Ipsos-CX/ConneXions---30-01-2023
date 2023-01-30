CREATE VIEW [DealerManagement].[vwApprovedUser_Change]
AS 

/*
	Purpose:	Return ApprovedUser update differences
	
	Release		Version		Date		Deveoloper				Comment
	LIVE		1.0			17/01/2022	Ben King     			750 - New APO column in FIMs - Ben

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

	
		FL.[ApprovedUser] AS ApprovedUser_UPDATE,
		F.[ApprovedUser] AS ApprovedUser_ORIGINAL

	FROM DealerManagement.[Franchises_Load] FL
	INNER JOIN [Lookup].[FranchiseTypes_Questionnaire] FQ ON FL.FranchiseType = FQ.FranchiseType
	INNER JOIN [$(SampleDB)].[dbo].[Markets] M ON FL.FranchiseCountry = M.FranchiseCountry
	INNER JOIN [$(SampleDB)].[dbo].[vwBrandMarketQuestionnaireSampleMetadata] VW ON M.Market = VW.Market
																	     AND FQ.BMQQuestionnaire = VW.Questionnaire
																		 AND FL.Brand = VW.Brand 
	INNER JOIN [$(SampleDB)].[DealerManagement].[Franchises_Load] F ON FL.[10CharacterCode] = F.[10CharacterCode]
											   AND FL.FranchiseType = F.FranchiseType
											   AND FL.FranchiseCountry = F.FranchiseCountry
	WHERE FL.[ApprovedUser] 
	  <>  F.[ApprovedUser] 

GO