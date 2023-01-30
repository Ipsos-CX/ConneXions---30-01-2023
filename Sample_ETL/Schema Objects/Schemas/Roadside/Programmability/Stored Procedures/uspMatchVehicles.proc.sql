CREATE PROCEDURE Roadside.uspMatchVehicles
AS

/*
	Purpose:	Uses VIN and ManufacturerPartyID to match vehicles in Roadside table to those in Sample db 
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Chris Ross		Created from [Sample_ETL].Warranty.uspMatchVehicles
	1.1				14-10-2013		Chris Ross			Bug 8976 - Only update where the PerformNormalVWTLoadFlag is set to 'N' i.e. we are 
														doing non-standard system loading/matching.

*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- MATCH JAGUAR VEHICLES
	UPDATE WE
	SET WE.MatchedODSVehicleID = V.VehicleID
	FROM Roadside.RoadsideEvents WE
	INNER JOIN [$(SampleDB)].Vehicle.Vehicles V ON V.VIN = WE.VIN
	INNER JOIN [$(SampleDB)].Vehicle.Models M ON M.ModelID = V.ModelID
										AND M.ManufacturerPartyID = WE.ManufacturerID
	WHERE ISNULL(WE.MatchedODSVehicleID, 0) = 0
	AND WE.ManufacturerID = (SELECT ManufacturerPartyID FROM [$(SampleDB)].dbo.Brands WHERE Brand = 'Jaguar')
	AND WE.PerformNormalVWTLoadFlag = 'N'		-- v1.1
	AND COALESCE(NULLIF(WE.MatchedODSEmailAddress1ID, 0), NULLIF(MatchedODSEmailAddress2ID ,0)) IS NULL		-- BUG 12659 - 12-05-2016 - Extra check to filter out those that have already matched on Name + Email address.
	

	-- MATCH LAND ROVER VEHICLES

	-- CHECK LENGTH OF VIN IN VEHICLE TABLE.
	-- IF IT LOOKS VALID BUT IS MISSING MANUFACTURER CODE PREFIX, add this before doing comparison
	UPDATE WE
	SET WE.MatchedODSVehicleID = V.VehicleID
	FROM Roadside.RoadsideEvents WE
	INNER JOIN [$(SampleDB)].Vehicle.Vehicles V ON V.VIN = WE.VIN
	INNER JOIN [$(SampleDB)].Vehicle.Models M ON M.ModelID = V.ModelID
										AND M.ManufacturerPartyID = WE.ManufacturerID
	WHERE ISNULL(WE.MatchedODSVehicleID, 0) = 0
	AND WE.ManufacturerID = (SELECT ManufacturerPartyID FROM [$(SampleDB)].dbo.Brands WHERE Brand = 'Land Rover')
	AND WE.PerformNormalVWTLoadFlag = 'N'		-- v1.1
	AND COALESCE(NULLIF(WE.MatchedODSEmailAddress1ID, 0), NULLIF(MatchedODSEmailAddress2ID ,0)) IS NULL		-- BUG 12659 - 12-05-2016 - Extra check to filter out those that have already matched on Name + Email address.


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