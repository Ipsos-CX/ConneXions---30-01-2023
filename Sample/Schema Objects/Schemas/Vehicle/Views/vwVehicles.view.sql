CREATE VIEW [Vehicle].[vwVehicles]

AS

/*
		Purpose:	Simple view of Vehicles table to be referenced in loading
	
		Version		Date			Developer			Comment
LIVE	1.0			$(ReleaseDate)	Simon Peacock		Created
LIVE	1.1			2022-03-17		Chris Ledger		TASK 729 - Add VehicleIdentificationNumberUsable, ModelVariantID & ModelYear fields
*/

SELECT
	V.VIN,
	V.VehicleID,
	V.ModelID,
	V.ModelVariantID,							-- V1.1
	M.ManufacturerPartyID AS ManufacturerID,
	V.VIN AS VehicleChecksum,
	V.VehicleIdentificationNumberUsable,		-- V1.1
	V.BuildYear AS ModelYear					-- V1.1
FROM Vehicle.Vehicles V
	INNER JOIN Vehicle.Models M ON M.ModelID = V.ModelID




