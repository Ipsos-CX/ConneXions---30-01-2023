CREATE TABLE [SampleVolumeAnalysis].[BaseTable]
(
	[Market] [varchar](200) NULL,
	[Questionnaire] [varchar](255) NULL,
	[Brand] [nvarchar](510) NULL,
	[AuditItemID] [bigint] NOT NULL,
	[LoadedDate] [datetime2](7) NOT NULL,
	[LoadedYear] [int] NULL,
	[LoadedMonth] [int] NULL,
	[LoadedWeek] [int] NULL,
	[MatchedODSEventID] [bigint] NOT NULL,
	[CaseID] [varchar](11) NULL,
	[CaseStatusType] [varchar](100) NULL,
	[ContactedCaseID] [varchar](11) NULL,
	[ResponseDate] [datetime2](7) NULL,
	[ResponseYear] [int] NULL,
	[ResponseMonth] [int] NULL,
	[ResponseWeek] [int] NULL,
	[RespondedCaseID] [varchar](11) NULL
)


