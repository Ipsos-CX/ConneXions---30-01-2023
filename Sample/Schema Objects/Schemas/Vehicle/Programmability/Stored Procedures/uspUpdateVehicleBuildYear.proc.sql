CREATE PROCEDURE [Vehicle].[uspUpdateVehicleBuildYear]

/*
		Purpose:	Update Sample database Vehicle table with vehicle modelyear
	
		Version		Date			Developer			Comment
LIVE	1.0			$(ReleaseDate)  Attila Kubanda		Update Vehicle table
LIVE	1.1			2019-05-09		Chris Ledger		BUG 15387: Add ModelID so that from 2019 ModelYear is dependent on ModelID and coded first.
LIVE	1.2			2022-03-24		Chris Ledger		TASK 729: Update model dependent & model non dependent model years in single query.
LIVE	1.3			2022-04-21		Chris Ledger		TASK 729: Update XJ Model based on VIN12thCharacter.
*/

AS

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

		-- V1.2 UPDATE MODEL DEPENDENT & NON MODEL DEPENDENT YEARS
		UPDATE V
		SET V.BuildYear = COALESCE(MY1.ModelYear, MY2.ModelYear, MY3.ModelYear)							-- V1.3
		FROM Vehicle.Vehicles V
			INNER JOIN Vehicle.Models M ON V.ModelID = M.ModelID
			LEFT JOIN Vehicle.ModelYear MY1 ON MY1.VIN12thCharacter = SUBSTRING(V.VIN, 12, 1)			-- V1.3
												AND MY1.VINCharacter = SUBSTRING(V.VIN, 10, 1)			-- V1.3
												AND M.ManufacturerPartyID = MY1.ManufacturerPartyID		-- V1.3
												AND M.ModelID = MY1.ModelID								-- V1.3
			LEFT JOIN Vehicle.ModelYear MY2 ON MY2.VINCharacter = SUBSTRING(V.VIN, 10, 1) 
												AND M.ManufacturerPartyID = MY2.ManufacturerPartyID
												AND M.ModelID = MY2.ModelID
												AND MY2.VIN12thCharacter IS NULL						-- V1.3
			LEFT JOIN Vehicle.ModelYear MY3 ON MY3.VINCharacter = SUBSTRING(V.VIN, 10, 1) 
												AND M.ManufacturerPartyID = MY3.ManufacturerPartyID
												AND MY3.ModelID IS NULL
		WHERE V.BuildYear IS NULL


		/*
		-- V1.1 UPDATE MODEL DEPENDENT YEARS - 2020 ONWARDS
		UPDATE V
		SET V.BuildYear = MY.ModelYear
		FROM Vehicle.Vehicles V
			INNER JOIN Vehicle.Models M ON V.ModelID = M.ModelID				-- V1.1
			INNER JOIN Vehicle.ModelYear MY ON MY.VINCharacter = SUBSTRING(V.VIN, 10, 1) 
												AND M.ManufacturerPartyID = MY.ManufacturerPartyID
												AND M.ModelID = MY.ModelID		-- V1.1
		WHERE V.BuildYear IS NULL


		-- V1.1 UPDATE NON MODEL DEPENDENT YEARS - PRE 2020
		UPDATE V
		SET V.BuildYear = MY.ModelYear
		FROM Vehicle.Vehicles V
			INNER JOIN Vehicle.Models M ON V.ModelID = M.ModelID				-- V1.1
			INNER JOIN Vehicle.ModelYear MY ON MY.VINCharacter = SUBSTRING(V.VIN, 10, 1) 
												AND M.ManufacturerPartyID = MY.ManufacturerPartyID
		WHERE V.BuildYear IS NULL
		AND MY.ModelID IS NULL
		*/
		
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
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH