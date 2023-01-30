ALTER TABLE [FTP].[MarketAndUploadFolder]
	ADD CONSTRAINT [FK_MarketAndUploadFolder_FTPScriptMetadata]
	FOREIGN KEY ([FTPID])
	REFERENCES [dbo].[FTPScriptMetadata] ([FTPID])
