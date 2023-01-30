CREATE TABLE [WeeklySampleCheck].[LiveBrandMarketQuestionnaire](
	[Market] [nvarchar](255) NOT NULL,
	[Brand] [nvarchar](255) NOT NULL,
	[Questionnaire] [nvarchar](255) NOT NULL,
	[Frequency] [nvarchar](255) NULL,
	[ExpectedDays] [nvarchar](255) NULL,
	[VolumeReportOutput] [bit] NULL,
	[MedianDaily] [numeric](18, 0) NULL,
	[MedianDailyTimePeriod] [nvarchar](255) NULL,
	[MedianDailyFromDate] [datetime] NULL,
	[MedianWeekly] [numeric](18, 0) NULL,
	[MedianWeeklyTimePeriod] [nvarchar](255) NULL,
	[MedianWeeklyFromDate] [datetime] NULL
) ON [PRIMARY]