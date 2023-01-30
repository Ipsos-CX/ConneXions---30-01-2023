CREATE TABLE [Vehicle].[VehicleMatchingStrings]
(
	VehicleMatchingStringID dbo.VehicleMatchingStringID IDENTITY(1,1) NOT NULL, 
	VehicleMatchingStringTypeID dbo.VehicleMatchingStringTypeID NOT NULL,
	VehicleMatchingString VARCHAR(100) NOT NULL,
	ElevenCharacterVehicleMatchingString VARCHAR(100) NULL
)
