CREATE VIEW Vehicle.vwDA_Vehicles

AS

/*
		Purpose:	Simple view of Vehicles table to be referenced in loading
	
		Version		Date			Developer			Comment
LIVE	1.0			$(ReleaseDate)	Simon Peacock		Created
LIVE	1.1			2022-03-24		Chris Ledger		TASK 729 - Add ModelVariantID field
*/

SELECT
	CONVERT(BIGINT, 0) AS AuditItemID, 
	CONVERT(BIGINT, 0) AS VehicleParentAuditItemID, 
	VehicleID, 
	ModelID,
	ModelVariantID,												-- V1.1
	VIN, 
	VehicleIdentificationNumberUsable,
	CONVERT(NVARCHAR(200), '') AS ModelDescription,
	CONVERT(NVARCHAR(200), '') AS BodyStyleDescription,
	CONVERT(NVARCHAR(200), '') AS EngineDescription,
	CONVERT(NVARCHAR(200), '') AS TransmissionDescription,
	CONVERT(VARCHAR(20), '') AS BuildDateOrig, 
	BuildYear,
	ThroughDate
FROM Vehicle.Vehicles
