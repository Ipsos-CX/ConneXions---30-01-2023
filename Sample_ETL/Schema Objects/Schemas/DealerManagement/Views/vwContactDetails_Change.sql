CREATE VIEW [DealerManagement].[vwContactDetails_Change]
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

		FL.[Address1] AS Address1_UPDATE,
		F.[Address1] AS Address1_ORIGINAL,
		FL.[Address2] AS Address2_UPDATE,
		F.[Address2] AS Address2_ORIGINAL,
		FL.[Address3] AS Address3_UPDATE,
		F.[Address3] AS Address3_ORIGINAL,
		FL.[AddressTown] AS AddressTown_UPDATE,
		F.[AddressTown] AS AddressTown_ORIGINAL,
		FL.[AddressCountyDistrict] AS AddressCountyDistrict_UPDATE,
		F.[AddressCountyDistrict] AS AddressCountyDistrict_ORIGINAL,
		FL.[AddressPostcode] AS AddressPostcode_UPDATE,
		F.[AddressPostcode] AS AddressPostcode_ORIGINAL,
		FL.[AddressLatitude] AS AddressLatitude_UPDATE,
		F.[AddressLatitude] AS AddressLatitude_ORIGINAL,
		FL.[AddressLongitude] AS AddressLongitude_UPDATE,
		F.[AddressLongitude] AS AddressLongitude_ORIGINAL,
		FL.[AddressActivity] AS AddressActivity_UPDATE,
		F.[AddressActivity] AS AddressActivity_ORIGINAL,
		FL.[Telephone] AS Telephone_UPDATE,
		F.[Telephone] AS Telephone_ORIGINAL,
		FL.[Email] AS Email_UPDATE,
		F.[Email] AS Email_ORIGINAL,
		FL.[URL] AS URL_UPDATE,
		F.[URL] AS URL_ORIGINAL	
	FROM [DealerManagement].[Franchises_Load] FL
	INNER JOIN [Lookup].[FranchiseTypes_Questionnaire] FQ ON FL.FranchiseType = FQ.FranchiseType
	INNER JOIN [$(SampleDB)].[dbo].[Markets] M ON FL.FranchiseCountry = M.FranchiseCountry
	INNER JOIN [$(SampleDB)].[dbo].[vwBrandMarketQuestionnaireSampleMetadata] VW ON M.Market = VW.Market
																	     AND FQ.BMQQuestionnaire = VW.Questionnaire
																		 AND FL.Brand = VW.Brand 
	INNER JOIN [$(SampleDB)].[DealerManagement].[Franchises_Load] F ON FL.[10CharacterCode] = F.[10CharacterCode]
											   AND FL.FranchiseType = F.FranchiseType
											   AND FL.FranchiseCountry = F.FranchiseCountry
	WHERE CONCAT(FL.[Address1], FL.[Address2], FL.[Address3], FL.[AddressTown], FL.[AddressCountyDistrict], FL.[AddressPostcode],
		         FL.[AddressLatitude], FL.[AddressLongitude], FL.[AddressActivity], FL.[Telephone], FL.[Email], FL.[URL])
	<>
		  CONCAT(F.[Address1], F.[Address2], F.[Address3], F.[AddressTown], F.[AddressCountyDistrict], F.[AddressPostcode],
		         F.[AddressLatitude], F.[AddressLongitude], F.[AddressActivity], F.[Telephone], F.[Email], F.[URL])

	
	