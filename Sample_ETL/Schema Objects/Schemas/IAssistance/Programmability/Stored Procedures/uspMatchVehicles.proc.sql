CREATE PROCEDURE IAssistance.uspMatchVehicles
AS

/*
	Purpose:	Uses VIN and ManufacturerPartyID to match vehicles in IAssistance table to those in Sample DB 
	
	Version			Date			Developer			Comment
	1.0				2018-10-26		Chris Ledger		Created from Roadside.uspMatchVehicles
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- MATCH JAGUAR VEHICLES
	UPDATE IE
	SET IE.MatchedODSVehicleID = V.VehicleID
	FROM IAssistance.IAssistanceEvents IE
	INNER JOIN [$(SampleDB)].Vehicle.Vehicles V ON V.VIN = IE.VIN
	INNER JOIN [$(SampleDB)].Vehicle.Models M ON M.ModelID = V.ModelID
										AND M.ManufacturerPartyID = IE.ManufacturerID
	WHERE ISNULL(IE.MatchedODSVehicleID, 0) = 0
	AND IE.ManufacturerID = (SELECT ManufacturerPartyID FROM [$(SampleDB)].dbo.Brands WHERE Brand = 'Jaguar')
	AND IE.PerformNormalVWTLoadFlag = 'N'		-- v1.1
	AND COALESCE(NULLIF(IE.MatchedODSEmailAddress1ID, 0), NULLIF(IE.MatchedODSEmailAddress2ID ,0)) IS NULL
	

	-- MATCH LAND ROVER VEHICLES

	-- CHECK LENGTH OF VIN IN VEHICLE TABLE.
	-- IF IT LOOKS VALID BUT IS MISSING MANUFACTURER CODE PREFIX, add this before doing comparison
	UPDATE IE
	SET IE.MatchedODSVehicleID = V.VehicleID
	FROM IAssistance.IAssistanceEvents IE
	INNER JOIN [$(SampleDB)].Vehicle.Vehicles V ON V.VIN = IE.VIN
	INNER JOIN [$(SampleDB)].Vehicle.Models M ON M.ModelID = V.ModelID
										AND M.ManufacturerPartyID = IE.ManufacturerID
	WHERE ISNULL(IE.MatchedODSVehicleID, 0) = 0
	AND IE.ManufacturerID = (SELECT ManufacturerPartyID FROM [$(SampleDB)].dbo.Brands WHERE Brand = 'Land Rover')
	AND IE.PerformNormalVWTLoadFlag = 'N'		-- v1.1
	AND COALESCE(NULLIF(IE.MatchedODSEmailAddress1ID, 0), NULLIF(IE.MatchedODSEmailAddress2ID ,0)) IS NULL


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