CREATE TABLE [SampleReport].[SampleVolumeWeeklyOutput](
	[HeaderID] [int] NOT NULL,
	[Brand] [nvarchar](255) NOT NULL,
	[Market] [nvarchar](255) NOT NULL,
	[Questionnaire] [nvarchar](255) NOT NULL,
	[Frequency] [nvarchar](255) NOT NULL,
	[BenchMark] [nvarchar](255) NULL,
	[CurrentWeekLoaded] [nvarchar](255) NULL,
	[WeekMinus1Loaded] [nvarchar](255) NOT NULL,
	[WeekMinus2Loaded] [nvarchar](255) NOT NULL,
	[WeekMinus3Loaded] [nvarchar](255) NOT NULL,
	[WeekMinus4Loaded] [nvarchar](255) NOT NULL,
	[MonthTotal] [nvarchar](255) NOT NULL,
	[ReportDate] [datetime] NULL
) ON [PRIMARY]
