CREATE TABLE [Audit].[CustomerUpdate_ExtraVehicleFeed]
(
	[ID]					INT						NOT NULL,
	[AuditID]				dbo.AuditID				NOT NULL,
	[AuditItemID]			dbo.AuditItemID			NOT NULL,
	[ParentAuditItemID]		dbo.AuditItemID			NULL,
	[VIN]					dbo.VIN					NULL,
	[ProductionDateOrig]	NVARCHAR(99)			NULL,
	[ProductionMonthOrig]	NVARCHAR(99)			NULL,
	[CountrySold]			NVARCHAR(99)			NULL,
	[Plant]					NVARCHAR(40)			NULL,
	[VehicleLine]			NVARCHAR(99)			NULL,
	[ModelYearOrig]			NVARCHAR(99)			NULL,
	[BodyStyle]				NVARCHAR(99)			NULL,
	[Drive]					NVARCHAR(99)			NULL,
	[Transmission]			NVARCHAR(99)			NULL,
	[Engine]				NVARCHAR(99)			NULL,
	[ProductionDate]		DATETIME2				NULL,
	[ProductionMonth]		DATETIME2				NULL,
	[ModelYear]				INT						NULL
)
