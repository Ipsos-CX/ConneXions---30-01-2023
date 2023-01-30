CREATE TABLE [SampleReport].[SummaryFilesEvents](
	[Market] [varchar](100) NULL,
	[ScheduledFiles] [varchar](100) NULL,
	[ReceivedFiles] [varchar](100) NULL,
	[ActionDate] [datetime2](7) NULL,
	[DueDate] [datetime2](7) NULL,
	[FileRowCount] [int] NULL,
	[EventsLoaded] [int] NULL,
	[DaysLate] [int] NULL
) ON [PRIMARY]

GO
