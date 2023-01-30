CREATE PROCEDURE [Stage].[uspStandardise_Franchise_Hierarchy]
AS

/*
	Purpose:	Stanadise data & flag data errors which can not be processed
	
	Release			Version			Date			Developer			Comment
	LIVE			1.0				26-01-21		Ben King    		BUG 18055
	LIVE			1.1				17-03-21		Ben King			TASK 846

*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

SET LANGUAGE ENGLISH
SET DATEFORMAT DMY

BEGIN TRY

	--CONVERT DATE
	UPDATE Stage.Franchise_Hierarchy
	SET ConvertedFranchiseEndDate = CONVERT(DATE, FranchiseEndDate, 103)
	WHERE LEN(FranchiseEndDate) > 0 

	--CONVERT DATE
	--V1.1
	UPDATE Stage.Franchise_Hierarchy
	SET ConvertedFranchiseStartDate = CONVERT(DATE, FranchiseStartDate, 103)
	WHERE LEN(FranchiseStartDate) > 0 



	--RE-SET FLAG FOR EACH RE-RUN
	UPDATE F
	SET IP_KeepOriginal = 0
	FROM [$(SampleDB)].[DealerManagement].[Franchises_Load] F



	--Brand change Data Error
	UPDATE FH
	SET FH.IP_DataError = 'Brand has changed for existing combination of 10CharacterCode + FranchiseType + FranchiseCountry',
		FH.IP_KeepOriginal = 1
	FROM Stage.Franchise_Hierarchy FH
	INNER JOIN [Lookup].[FranchiseTypes_Questionnaire] FQ ON LTRIM(RTRIM(FH.FranchiseType)) = FQ.FranchiseType
	INNER JOIN [$(SampleDB)].[dbo].[Markets] M ON LTRIM(RTRIM(FH.FranchiseCountry)) = M.FranchiseCountry
	INNER JOIN [$(SampleDB)].[dbo].[vwBrandMarketQuestionnaireSampleMetadata] VW ON M.Market = VW.Market
																	     AND FQ.BMQQuestionnaire = VW.Questionnaire
																		 AND LTRIM(RTRIM(FH.Brand)) = VW.Brand 
	INNER JOIN [$(SampleDB)].[DealerManagement].[Franchises_Load] F ON LTRIM(RTRIM(FH.[10CharacterCode])) = F.[10CharacterCode]
											   AND LTRIM(RTRIM(FH.FranchiseType)) = F.FranchiseType
											   AND LTRIM(RTRIM(FH.FranchiseCountry)) = F.FranchiseCountry
	WHERE LTRIM(RTRIM(FH.Brand)) <> F.Brand



	--UPDATE RECORDS TO REMAIN FROM NEW FILE TRANSFER
	UPDATE F
	SET F.IP_KeepOriginal = 1
	FROM Stage.Franchise_Hierarchy FH
	INNER JOIN [Lookup].[FranchiseTypes_Questionnaire] FQ ON LTRIM(RTRIM(FH.FranchiseType)) = FQ.FranchiseType
	INNER JOIN [$(SampleDB)].[dbo].[Markets] M ON LTRIM(RTRIM(FH.FranchiseCountry)) = M.FranchiseCountry
	INNER JOIN [$(SampleDB)].[dbo].[vwBrandMarketQuestionnaireSampleMetadata] VW ON M.Market = VW.Market
																	     AND FQ.BMQQuestionnaire = VW.Questionnaire
																		 AND LTRIM(RTRIM(FH.Brand)) = VW.Brand 
	INNER JOIN [$(SampleDB)].[DealerManagement].[Franchises_Load] F ON LTRIM(RTRIM(FH.[10CharacterCode])) = F.[10CharacterCode]
											   AND LTRIM(RTRIM(FH.FranchiseType)) = F.FranchiseType
											   AND LTRIM(RTRIM(FH.FranchiseCountry)) = F.FranchiseCountry
	WHERE LTRIM(RTRIM(FH.Brand)) <> F.Brand




	--Franchise Type Data Error
	UPDATE FH
	SET FH.IP_DataError = 'Franchise Type Full Retailer can not change for combination of 10CharacterCode + Brand + FranchiseCountry + FranchiseCICode',
		FH.IP_KeepOriginal = 1
	--SELECT *
	FROM Stage.Franchise_Hierarchy FH
	INNER JOIN [Lookup].[FranchiseTypes_Questionnaire] FQ ON LTRIM(RTRIM(FH.FranchiseType)) = FQ.FranchiseType
	INNER JOIN [$(SampleDB)].[dbo].[Markets] M ON LTRIM(RTRIM(FH.FranchiseCountry)) = M.FranchiseCountry
	INNER JOIN [$(SampleDB)].[dbo].[vwBrandMarketQuestionnaireSampleMetadata] VW ON M.Market = VW.Market
																	     AND FQ.BMQQuestionnaire = VW.Questionnaire
																		 AND LTRIM(RTRIM(FH.Brand)) = VW.Brand 
	INNER JOIN [$(SampleDB)].[DealerManagement].[Franchises_Load] F ON LTRIM(RTRIM(FH.[10CharacterCode])) = F.[10CharacterCode]
											   AND LTRIM(RTRIM(FH.Brand)) = F.Brand
											   AND LTRIM(RTRIM(FH.FranchiseCountry)) = F.FranchiseCountry
											   AND LTRIM(RTRIM(FH.FranchiseCICode)) = F.FranchiseCICode
	WHERE LTRIM(RTRIM(FH.FranchiseType)) <> F.FranchiseType
	AND LTRIM(RTRIM(FH.FranchiseType)) = 'Full Retailer'



	--UPDATE RECORDS TO REMAIN FROM NEW FILE TRANSFER
	UPDATE F
	SET F.IP_KeepOriginal = 1
	--SELECT *
	FROM Stage.Franchise_Hierarchy FH
	INNER JOIN [Lookup].[FranchiseTypes_Questionnaire] FQ ON LTRIM(RTRIM(FH.FranchiseType)) = FQ.FranchiseType
	INNER JOIN [$(SampleDB)].[dbo].[Markets] M ON LTRIM(RTRIM(FH.FranchiseCountry)) = M.FranchiseCountry
	INNER JOIN [$(SampleDB)].[dbo].[vwBrandMarketQuestionnaireSampleMetadata] VW ON M.Market = VW.Market
																	     AND FQ.BMQQuestionnaire = VW.Questionnaire
																		 AND LTRIM(RTRIM(FH.Brand)) = VW.Brand 
	INNER JOIN [$(SampleDB)].[DealerManagement].[Franchises_Load] F ON LTRIM(RTRIM(FH.[10CharacterCode])) = F.[10CharacterCode]
											   AND LTRIM(RTRIM(FH.Brand)) = F.Brand
											   AND LTRIM(RTRIM(FH.FranchiseCountry)) = F.FranchiseCountry
											   AND LTRIM(RTRIM(FH.FranchiseCICode)) = F.FranchiseCICode
	WHERE LTRIM(RTRIM(FH.FranchiseType)) <> F.FranchiseType
	AND LTRIM(RTRIM(FH.FranchiseType)) = 'Full Retailer'




	--Franchise Type Data Error
	UPDATE FH
	SET FH.IP_DataError = 'Franchise Type Full Retailer can not change for combination of 10CharacterCode + Brand + FranchiseCountry + FranchiseCICode',
		FH.IP_KeepOriginal = 1
	--SELECT *
	FROM Stage.Franchise_Hierarchy FH
	INNER JOIN [Lookup].[FranchiseTypes_Questionnaire] FQ ON LTRIM(RTRIM(FH.FranchiseType)) = FQ.FranchiseType
	INNER JOIN [$(SampleDB)].[dbo].[Markets] M ON FH.FranchiseCountry = M.FranchiseCountry
	INNER JOIN [$(SampleDB)].[dbo].[vwBrandMarketQuestionnaireSampleMetadata] VW ON M.Market = VW.Market
																	     AND FQ.BMQQuestionnaire = VW.Questionnaire
																		 AND LTRIM(RTRIM(FH.Brand)) = VW.Brand 
	INNER JOIN [$(SampleDB)].[DealerManagement].[Franchises_Load] F ON LTRIM(RTRIM(FH.[10CharacterCode])) = F.[10CharacterCode]
											   AND LTRIM(RTRIM(FH.Brand)) = F.Brand
											   AND LTRIM(RTRIM(FH.FranchiseCountry)) = F.FranchiseCountry
											   AND LTRIM(RTRIM(FH.FranchiseCICode)) = F.FranchiseCICode
	WHERE LTRIM(RTRIM(FH.FranchiseType)) <> F.FranchiseType
	AND F.FranchiseType = 'Full Retailer'



	--UPDATE RECORDS TO REMAIN FROM NEW FILE TRANSFER
	UPDATE F
	SET F.IP_KeepOriginal = 1
	--SELECT *
	FROM Stage.Franchise_Hierarchy FH
	INNER JOIN [Lookup].[FranchiseTypes_Questionnaire] FQ ON LTRIM(RTRIM(FH.FranchiseType)) = FQ.FranchiseType
	INNER JOIN [$(SampleDB)].[dbo].[Markets] M ON FH.FranchiseCountry = M.FranchiseCountry
	INNER JOIN [$(SampleDB)].[dbo].[vwBrandMarketQuestionnaireSampleMetadata] VW ON M.Market = VW.Market
																	     AND FQ.BMQQuestionnaire = VW.Questionnaire
																		 AND LTRIM(RTRIM(FH.Brand)) = VW.Brand 
	INNER JOIN [$(SampleDB)].[DealerManagement].[Franchises_Load] F ON LTRIM(RTRIM(FH.[10CharacterCode])) = F.[10CharacterCode]
											   AND LTRIM(RTRIM(FH.Brand)) = F.Brand
											   AND LTRIM(RTRIM(FH.FranchiseCountry)) = F.FranchiseCountry
											   AND LTRIM(RTRIM(FH.FranchiseCICode)) = F.FranchiseCICode
	WHERE LTRIM(RTRIM(FH.FranchiseType)) <> F.FranchiseType
	AND F.FranchiseType = 'Full Retailer'



	--CHECK 10CharacterCode consists of Franchise CI Code
	UPDATE F
	SET F.IP_DataError = 'FranchiseCICode is not contained within 10CharacterCode'
	--SELECT *
	FROM Stage.Franchise_Hierarchy F
	WHERE LTRIM(RTRIM(F.[10CharacterCode])) NOT LIKE + '%' + F.FranchiseCICode




	--Check Brand Text
	UPDATE F
	SET F.IP_DataError = 'Brand text has to be either Jaguar OR Land Rover'
	--SELECT *
	FROM Stage.Franchise_Hierarchy F
	WHERE LTRIM(RTRIM(F.Brand)) NOT IN ('Jaguar','Land Rover')




	--Check Duplicate Rows
	UPDATE F
	SET F.IP_DataError = 'Duplicate 10CharacterCode + FranchiseType + FranchiseCountry'
	--SELECT DISTINCT * 
	FROM [Stage].[Franchise_Hierarchy] F
	INNER JOIN (
					SELECT 
						LTRIM(RTRIM([10CharacterCode])) AS '10CharacterCode', 
						LTRIM(RTRIM(FranchiseType)) AS 'FranchiseType', 
						LTRIM(RTRIM(FranchiseCountry)) AS 'FranchiseCountry', 
						COUNT(FranchiseCountry) AS COUNT
					FROM [Stage].[Franchise_Hierarchy]
					GROUP BY [10CharacterCode], FranchiseType, FranchiseCountry
					HAVING COUNT(FranchiseCountry) > 1
				) C ON
					LTRIM(RTRIM(F.FranchiseCountry)) = C.FranchiseCountry
				AND LTRIM(RTRIM(F.FranchiseType)) = C.FranchiseType
				AND LTRIM(RTRIM(F.[10CharacterCode])) = C.[10CharacterCode]




	--Set validatoin flag
	UPDATE F
	SET F.IP_StagingDataValidated = CASE 
								WHEN F.IP_DataError IS NULL THEN 1
								ELSE 0
							 END
	FROM [Stage].[Franchise_Hierarchy] F
		
	
END TRY
BEGIN CATCH

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [$(ErrorDB)].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
		
	-- CREATE A COPY OF THE STAGING TABLE FOR USE IN PRODUCTION SUPPORT
	DECLARE @TimestampString CHAR(15)
	SELECT @TimestampString = [$(ErrorDB)].dbo.udfGetTimestampString(GETDATE())
	
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
END CATCH


GO