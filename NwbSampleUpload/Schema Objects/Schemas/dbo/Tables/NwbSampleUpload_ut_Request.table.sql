CREATE TABLE [NwbSampleUpload_ut_Request]
(
	[pkNwbSampleUploadRequestKey] INT IDENTITY(1,1) NOT NULL,
	[fkSampleUploadStatusKey] INT NULL,
	[ProjectId] NVARCHAR(512) NOT NULL,
	[fkSampleUploadInputTypeKey] INT NOT NULL,
	[InputPath] NVARCHAR(512) NOT NULL,
	[InputParameter] NVARCHAR(512) NOT NULL,
	[HubName] NVARCHAR(512) NOT NULL,
	[TargetServerName] NVARCHAR(512) NOT NULL,
	[ReRandomizeSortId] BIT NOT NULL, 
	[CreatedTimestamp] DATETIME NOT NULL,
	[ModifiedTimestamp] DATETIME NOT NULL,
	[QueuedTimestamp] DATETIME NULL,
	[StartedTimestamp] DATETIME NULL,
	[CompletedTimestamp] DATETIME NULL,
	CONSTRAINT [pk_NwbSampleUploadRequestKey] PRIMARY KEY CLUSTERED 
	(
		[pkNwbSampleUploadRequestKey] ASC
	) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]