CREATE TABLE [FTP].[MarketAndUploadFolder]
(
	[MarketAndUploadFolderID] [int] IDENTITY(1,1) NOT NULL,
	[FTPID] [int] NOT NULL,
	[MarketID] [int] NOT NULL,
	[UploadFolderID] [int] NOT NULL
)
