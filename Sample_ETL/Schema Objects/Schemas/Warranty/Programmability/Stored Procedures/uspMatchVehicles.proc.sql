CREATE PROCEDURE Warranty.uspMatchVehicles
AS

/*
	Purpose:	Uses VIN and ManufacturerPartyID to match vehicles in Warranty table to those in Sample db 
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspMATCH_WarrantyVehicles

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
	FROM Warranty.WarrantyEvents WE
	INNER JOIN [$(SampleDB)].Vehicle.Vehicles V ON LTRIM(RTRIM(ISNULL(NULLIF(V.ChassisNumber, ''), RIGHT(V.VIN, 6)))) = WE.ChassisNumber
	INNER JOIN [$(SampleDB)].Vehicle.Models M ON M.ModelID = V.ModelID
										AND M.ManufacturerPartyID = WE.ManufacturerID
	WHERE ISNULL(WE.MatchedODSVehicleID, 0) = 0
	AND WE.ManufacturerID = (SELECT ManufacturerPartyID FROM [$(SampleDB)].dbo.Brands WHERE Brand = 'Jaguar')


	-- MATCH LAND ROVER VEHICLES

	-- CHECK LENGTH OF VIN IN VEHICLE TABLE.
	-- IF IT LOOKS VALID BUT IS MISSING MANUFACTURER CODE PREFIX, add this before doing comparison
	UPDATE WE
	SET WE.MatchedODSVehicleID = V.VehicleID
	FROM Warranty.WarrantyEvents WE
	INNER JOIN [$(SampleDB)].Vehicle.Vehicles V ON CASE 
												WHEN LEN(V.VIN) = 11 AND V.VIN NOT LIKE 'SAL%' THEN N'SAL' + V.VIN 
												ELSE V.VIN
											END = WE.VINPrefix + WE.ChassisNumber
	INNER JOIN [$(SampleDB)].Vehicle.Models M ON M.ModelID = V.ModelID
										AND M.ManufacturerPartyID = WE.ManufacturerID
	WHERE ISNULL(WE.MatchedODSVehicleID, 0) = 0
	AND WE.ManufacturerID = (SELECT ManufacturerPartyID FROM [$(SampleDB)].dbo.Brands WHERE Brand = 'Land Rover')

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