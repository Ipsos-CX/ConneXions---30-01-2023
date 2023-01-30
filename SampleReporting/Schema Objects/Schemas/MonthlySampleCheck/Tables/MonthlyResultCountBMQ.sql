CREATE TABLE [MonthlySampleCheck].[MonthlyResultCountBMQ]
(
	[Market] [nvarchar](255) NULL,
	[Brand] [nvarchar](255) NULL,
	[Questionnaire] [nvarchar](255) NULL,
	[Frequency] [nvarchar](255) NULL,
	[File_Count] [int] NULL,
	[FileRow_Count] [bigint] NULL,
	[FileRow_LoadedCount] [int] NULL,
	[Selected_Count] [int] NULL,
	[ResultMonth] [nvarchar](255) NULL,
	[ResultYear] [nvarchar](255) NULL,
	[ResultDate] [datetime2](7) NULL
)
