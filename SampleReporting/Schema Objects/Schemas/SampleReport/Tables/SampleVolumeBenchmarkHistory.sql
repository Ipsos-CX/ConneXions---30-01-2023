CREATE TABLE [SampleReport].[SampleVolumeBenchmarkHistory](
	[Brand] [nvarchar](255) NULL,
	[Market] [nvarchar](255) NULL,
	[Questionnaire] [nvarchar](255) NULL,
	[TimePeriod] [varchar](10) NOT NULL,
	[BenchmarkType] [varchar](18) NOT NULL,
	[Median] [numeric](18, 0) NULL,
	[ReportDate] [date] NULL
) ON [PRIMARY]
GO
