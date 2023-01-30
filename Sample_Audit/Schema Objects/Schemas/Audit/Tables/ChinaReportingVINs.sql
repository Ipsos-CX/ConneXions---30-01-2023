CREATE TABLE [Audit].[ChinaReportingVINs]
(
	[AuditID] [dbo].[AuditID] NULL,
	[AuditItemID] [dbo].[AuditItemID] NULL,
	[PhysicalRowID] [int] NULL,
	[VIN] [NVARCHAR] (50) NOT NULL --BUG 18109
)
