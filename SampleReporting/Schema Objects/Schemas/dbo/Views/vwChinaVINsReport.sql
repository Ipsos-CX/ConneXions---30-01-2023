CREATE VIEW [dbo].[vwChinaVINsReport]

AS 

/*

Purpose:	Return data to be fed into China VINs Report
	
				Version		Date		Deveoloper				Comment
	LIVE		1.0			2021-03-16  Ben King				BUG 18109 - China VINs Report
	LIVE		1.1			2021-08-06	Eddie Thomas			BUG 18304 - VIN decoder amendments 
	LIVE		1.2         2022-03-17  Ben King                TASK 824 - Incoming Feed China VINs change
	LIVE		1.3			2022-09-26	Eddie Thomas			TASK 1017 - Added SubBrand
	
*/

	SELECT DISTINCT
		CASE 
			WHEN RIGHT(VIN,1) = '+' THEN LEFT(VIN,12)
			ELSE VIN
		END AS VIN, -- V1.2
		ModelID, 
		ModelDescription, 
		ModelVariantID, 
		Variant, 
		EV_FLAG,
		SVOType,		--V1.1
		ModelCode,		--V1.1
		ModelYear,		--V1.1
		SubBrand		--V1.3
	FROM [dbo].[ChinaVINsReport]
	WHERE CONVERT(DATE,ReportDate) = CONVERT(DATE,GETDATE())

GO
