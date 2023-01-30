CREATE TABLE [CRM].[FilteredRecords](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[CRMTableName] VARCHAR(256),
	[CRMTableID] [int] NOT NULL,
	[AuditID] [dbo].[AuditID] NULL,
	[AuditItemID] [dbo].[AuditItemID] NULL,
	[PhysicalRowID] [int] NOT NULL,
	[DateFiltered]  DATETIME NOT NULL,
	[FilteredReason] VARCHAR(512)  NOT NULL
) ON [PRIMARY]