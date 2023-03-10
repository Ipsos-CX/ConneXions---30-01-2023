CREATE TABLE [SampleVolumeAnalysis].[WeeklyTotals](
	[Market] [varchar](200) NOT NULL,
	[Questionnaire] [varchar](255) NOT NULL,
	[Brand] [nvarchar](510) NOT NULL,
	[ReportDate] [datetime] NOT NULL,
	[CurrentYear] [int] NOT NULL,
	[CurrentWeek] [int] NOT NULL,
	[PrevWeek1] [int] NULL,
	[PrevWeek2] [int] NULL,
	[YTD_TotalEvents] [bigint] NULL,
	[PW2_TotalEvents] [bigint] NULL,
	[PW1_TotalEvents] [bigint] NULL,
	[TotalEventsVariance] [decimal](6, 2) NULL,
	[YTD_Contacted] [bigint] NULL,
	[PW2_Contacted] [bigint] NULL,
	[PW1_Contacted] [bigint] NULL,
	[ContactedVariance] [decimal](6, 2) NULL,
	[YTD_Responses] [bigint] NULL,
	[PW2_Responses] [bigint] NULL,
	[PW1_Responses] [bigint] NULL,
	[ResponsesVariance] [decimal](6, 2) NULL
) 
