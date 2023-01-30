CREATE TABLE [dbo].[Timings]
(
	[TimingId] [int] IDENTITY(1,1) NOT NULL,
	[ProcessName] [varchar](100) NOT NULL,
	[SubProcessName] [varchar](500) NOT NULL,
	[NumberOfRowsProcessed] [int] NULL,
	[StartTime] [datetime] NOT NULL,
	[EndTime] [datetime] NULL,
	[TimeTakenMinutes] [int] NULL
)
