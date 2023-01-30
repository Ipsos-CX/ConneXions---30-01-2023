CREATE VIEW [Vehicle].[vwDA_VehicleRegistrationEvents]

AS

SELECT 
	CONVERT(BIGINT, 0) AS AuditItemID, 
	VehicleID,
	RegistrationID,
	EventID,
	CAST('' AS NVARCHAR(200)) AS RegNumber,
	CAST(NULL AS DATETIME2) AS RegistrationDate,
	CAST('' AS VARCHAR(50)) AS RegistrationDateOrig
FROM Vehicle.VehicleRegistrationEvents
