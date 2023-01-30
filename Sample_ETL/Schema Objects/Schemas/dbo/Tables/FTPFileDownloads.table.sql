CREATE TABLE [dbo].[FTPFileDownloads] (
    [FileDownloadID]	INT IDENTITY(1,1)      NOT NULL,
    [FileName]			VARCHAR(100) NOT NULL,
    [Date]			 SMALLDATETIME NOT NULL
);

