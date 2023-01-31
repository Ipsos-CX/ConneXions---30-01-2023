CREATE TABLE [SampleReport].[DailySampleVolumeBMQ](
	[Build] [nvarchar](20) NULL,
	[Market] [nvarchar](255) NULL,
	[Brand] [nvarchar](255) NULL,
	[Questionnaire] [nvarchar](255) NULL,
	[Frequency] [nvarchar](200) NULL,
	[File_Count] [int] NULL,
	[FileRow_Count] [bigint] NULL,
	[FileRow_LoadedCount] [int] NULL,
	[Selected_Count] [int] NULL,
	[ResultDate] [datetime] NULL,
	[ReportDate] [datetime] NULL
) ON [PRIMARY]

