CREATE TABLE [Stage].[Chinese_VINs]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AuditID] [dbo].[AuditID] NULL,
	[AuditItemID] [dbo].[AuditItemID] NULL,
	[PhysicalRowID] [int] NULL,
	[VIN] [NVARCHAR] (50) NOT NULL,
	[VehicleParentAuditItemID] [int] NULL --TASK 824
)
