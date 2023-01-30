CREATE TABLE [Canada].[Service_FilteredRecords]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AuditID] [dbo].[AuditID] NOT NULL,
	[PhysicalRowID] [int] NOT NULL,
   [FilterReasons]			VARCHAR(MAX),
    [FilterFailedValues]	VARCHAR(MAX)

)
