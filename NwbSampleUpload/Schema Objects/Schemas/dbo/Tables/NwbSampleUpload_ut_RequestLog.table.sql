CREATE TABLE [NwbSampleUpload_ut_RequestLog]
(
	[pkNwbSampleUploadRequestLogKey] INT IDENTITY(1,1) NOT NULL,
	[fkNwbSampleUploadRequestKey] INT NULL,
	[LogText] NVARCHAR(1024) NOT NULL,
	[CreatedTimestamp] DATETIME NOT NULL,
	[ModifiedTimestamp] DATETIME NOT NULL,
	CONSTRAINT [pk_NwbSampleUploadRequestLogKey] PRIMARY KEY CLUSTERED 
	(
		[pkNwbSampleUploadRequestLogKey] ASC
	) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]