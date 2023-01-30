CREATE PROCEDURE [Vehicle].[uspUpdateVehicleModelVariantIDByModelYear]

/*
		Purpose:	Update Vehicle table ModelVariantID based on Model Year
	
		Version		Date			Developer			Comment
LIVE	1.1			2022-03-24		Chris Ledger		TASK 729: Update Vehicle table ModelVariantID based on Model Year

*/

AS

UPDATE V
SET V.ModelVariantID = COALESCE(MVMYM.ModelVariantID, MVMYM1.ModelVariantID)
FROM Vehicle.Vehicles V
	LEFT JOIN Vehicle.ModelVariantModelYearMatching MVMYM ON V.ModelID = MVMYM.ModelID
																	AND V.BuildYear = MVMYM.ModelYear
	LEFT JOIN Vehicle.ModelVariantModelYearMatching MVMYM1 ON V.ModelID = MVMYM1.ModelID
																	AND MVMYM1.ModelYear IS NULL
WHERE V.ModelVariantID IS NULL
