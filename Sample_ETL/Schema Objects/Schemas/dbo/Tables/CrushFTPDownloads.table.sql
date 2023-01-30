CREATE TABLE [dbo].[CrushFTPDownloads](
	[CrushFTPDownloadID]	[int] IDENTITY(1,1) NOT NULL,
	[CrushFTPDownloadName] [varchar](50) NOT NULL,
	[LocalServerName]		[nvarchar](512) NOT NULL,
	[Description]			[varchar](100) NOT NULL,
	[Market]				[dbo].[Country]				NULL,
    [Questionnaire]			[varchar](255)				NULL,
 	[Brand]					[dbo].[OrganisationName]	NULL,
	[CrushFTPLoginID]		INT NOT NULL,
	[RemoteDirectory]		[varchar](255) NOT NULL,
	[FilenameFilterMask]	[varchar](50) NOT NULL,
	[IncludeAllRemoteSubdirectoies] [bit] NOT NULL,
	[StampFileNameWithRemoteDirName] [bit] NOT NULL,
	[LocalDownloadDirectory] [varchar](255) NULL,
	[DeleteRemoteFileAfterDownload] [bit] NOT NULL,
	[ArchiveCopyOfEncryptedFile][bit] NOT NULL,
	[TransferMode] [varchar](50) NOT NULL,
	[Enabled] [bit] NOT NULL
);

