CREATE TABLE [ParallelRun].[FileSummary](
	[FileName] [nvarchar](255) NULL,
	[Sucess] [bit] NOT NULL,
	[GfK FileRowCount] [float] NULL,
	[GfK Events] [float] NULL,
	[GfK Cases] [float] NULL,
	[IPSOS FileRowCount] [float] NULL,
	[IPSOS Events] [float] NULL,
	[IPSOS Cases] [float] NULL,
	[Events] [nvarchar](255) NULL,
	[Cases] [nvarchar](255) NULL,
	[Difference] [nvarchar](255) NULL
) ON [PRIMARY]