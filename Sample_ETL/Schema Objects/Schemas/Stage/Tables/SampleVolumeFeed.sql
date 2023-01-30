CREATE TABLE [Stage].[SampleVolumeFeed](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AuditID] [dbo].[AuditID] NULL,
	[AuditItemID] [dbo].[AuditItemID] NULL,
	[PhysicalRowID] [int] NULL,
	[IP_DataError] [nvarchar](255) NULL,
	[Brand] [dbo].[OrganisationName] NOT NULL,
	[Market] [dbo].[Country] NOT NULL,
	[Questionnaire] [varchar](100) NOT NULL,
	[Frequency] [nvarchar](255) NULL,
	[ExpectedDays] [nvarchar](255) NULL,
	[VolumeReportOutput] [int] NULL
) ON [PRIMARY]
