CREATE TABLE [Vehicle].[ExtraVehicleFeed]
(
	[VIN]					dbo.VIN					NOT NULL,
	[ProductionDate]		DATETIME2				NULL,
	[ProductionMonth]		DATETIME2				NULL,
	[CountrySold]			NVARCHAR(99)			NULL,
	[Plant]					NVARCHAR(40)			NULL,
	[VehicleLine]			NVARCHAR(99)			NULL,
	[ModelYear]				INT						NULL,
	[BodyStyle]				NVARCHAR(99)			NULL,
	[Drive]					NVARCHAR(99)			NULL,
	[Transmission]			NVARCHAR(99)			NULL,
	[Engine]				NVARCHAR(99)			NULL,
	[ModelID]				INT						NULL,
	[ModelVariantID]		INT						NULL,
	[DateReOutput]			DATETIME2				NULL,
	[OldModelID]			INT						NULL,
	[OldModelVariantID]		INT						NULL
)
