CREATE VIEW [dbo].[vwVWT_Vehicles]
AS

/*
		Purpose:	Simple view of Vehicles table to be referenced in loading
	
		Version		Date			Developer			Comment
LIVE	1.0			$(ReleaseDate)	Simon Peacock		Created
LIVE	1.1			2022-03-17		Chris Ledger		TASK 729 - Add MatchedModelVariantID & MatchedModelYear fields
*/

SELECT 
	AuditItemID,
	VehicleIdentificationNumber,
	MatchedODSVehicleID,
	MatchedODSModelID,
	ManufacturerID,
	VehicleIdentificationNumberUsable AS Usable,
	VehicleParentAuditItemID,
	MatchedModelVariantID,							-- V1.1
	MatchedModelYear,								-- V1.1
	VehicleIdentificationNumber AS VehicleChecksum 
FROM dbo.VWT;






