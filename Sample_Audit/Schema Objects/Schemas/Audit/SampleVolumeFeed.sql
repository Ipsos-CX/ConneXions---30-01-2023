CREATE TABLE [Audit].[SampleVolumeFeed](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AuditID] [dbo].[AuditID] NULL,
	[AuditItemID] [dbo].[AuditItemID] NULL,
	[PhysicalRowID] [int] NULL,
	[Brand] [dbo].[OrganisationName] NOT NULL,
	[Market] [dbo].[Country] NOT NULL,
	[Questionnaire] [varchar](100) NOT NULL,
	[Frequency] [nvarchar](255) NULL,
	[ExpectedDays] [nvarchar](255) NULL,
	[VolumeReportOutput] [bit] NULL
) ON [PRIMARY]
