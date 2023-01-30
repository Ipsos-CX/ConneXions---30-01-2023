CREATE TABLE [ParallelRun].[Files](
	[AuditID] [bigint] NOT NULL,
	[FileTypeID] [int] NOT NULL,
	[FileName] [varchar](100) NOT NULL,
	[FileRowCount] [int] NULL,
	[ActionDate] [datetime2](7) NOT NULL,
	[FileChecksum] [int] NULL,
	[LoadSuccess] [bit] NULL,
	[FileLoadFailureID] [int] NULL
) 