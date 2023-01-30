CREATE TABLE [SampleReport].[SampleVolumeBenchmarks](
	[Market] [nvarchar](255) NULL,
	[Brand] [nvarchar](255) NULL,
	[Questionnaire] [nvarchar](255) NULL,
	[TimePeriod] [nvarchar](255) NULL,
	[StartDate] [datetime] NULL,
	[FileRow_LoadedCountWeekly] [int] NULL,
	[FileRow_LoadedCountDaily] [int] NULL,
	[ReportDate] [datetime] NULL
) ON [PRIMARY]
GO