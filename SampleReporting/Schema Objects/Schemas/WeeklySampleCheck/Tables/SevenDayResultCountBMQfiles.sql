CREATE TABLE [WeeklySampleCheck].[SevenDayResultCountBMQfiles](
	[Market] [nvarchar](255) NULL,
	[Brand] [nvarchar](255) NULL,
	[Questionnaire] [nvarchar](255) NULL,
	[Frequency] [nvarchar](255) NULL,
	[Files] [varchar](100) NULL,
	[LoadSuccess] [bit] NULL,
	[FileLoadFailure] [varchar](40) NULL,
	[FileRowCount] [int] NULL,
	[AuditID] [bigint] NULL,
	[FileRow_LoadedCount] [int] NULL,
	[Selected_Count] [int] NULL,
	[ResultDay] [datetime] NULL
) ON [PRIMARY]
