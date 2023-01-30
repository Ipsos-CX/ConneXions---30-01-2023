CREATE VIEW Load.vwVehicles

/*
		Purpose:	View used to load Vehicles
	
		Version		Date			Developer			Comment
LIVE	1.1			2021-06-04		Chris Ledger		Task 729 - add MatchedModelVariantID & MatchedModelYear		
*/

AS

SELECT
	AuditItemID,
	VehicleParentAuditItemID,
	MatchedODSVehicleID, 
	MatchedODSModelID,
	MatchedModelVariantID,			-- V1.1
	ISNULL(VehicleIdentificationNumber, N'') as VehicleIdentificationNumber, 
	VehicleIdentificationNumberUsable, 
	ModelDescription,
	BodyStyleDescription,
	EngineDescription,
	TransmissionDescription,
	BuildDateOrig, 
	MatchedModelYear AS BuildYear	-- V1.1
FROM dbo.VWT
WHERE ManufacturerID > 0
