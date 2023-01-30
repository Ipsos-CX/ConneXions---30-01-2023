CREATE TABLE [Stage].[AFRLCodeLookupData](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AuditID]  BIGINT	NULL,
	[Marque] [NVARCHAR](500) NULL,
	[Vin Chassis Frame Number] [NVARCHAR](500) NULL,
	[Registration Date] [NVARCHAR](500) NULL,
	[Registration Mark] [NVARCHAR](500) NULL,
	[Detailed Sales Type Code] [NVARCHAR](500) NULL
);
