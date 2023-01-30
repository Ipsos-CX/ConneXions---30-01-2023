CREATE TABLE [SampleVolumeAnalysis].[MonthlyTotals]
(
	[Market] [varchar](200) NOT NULL,
	[Questionnaire] [varchar](255) NOT NULL,
	[Brand] [nvarchar](510) NOT NULL,
	[ReportDate] [datetime] NOT NULL,
	[CurrentYear] [int] NULL,
	[CurrentMonth] [int] NULL,
	[ReportYear] [int] NOT NULL,
	[ReportMonth] [int] NOT NULL,
	[PreviousYear] [int] NULL,
	[PreviousMonth] [int] NULL,
	[TotalEvents] [bigint] NULL,
	[PM_TotalEvents] [bigint] NULL,
	[TotalEventsVariance] [decimal](6, 2) NULL,
	[Contacted] [bigint] NULL,
	[PM_Contacted] [bigint] NULL,
	[ContactedVariance] [decimal](6, 2) NULL,
	[Responses] [bigint] NULL,
	[PM_Responses] [bigint] NULL,
	[ResponsesVariance] [decimal](6, 2) NULL
)


