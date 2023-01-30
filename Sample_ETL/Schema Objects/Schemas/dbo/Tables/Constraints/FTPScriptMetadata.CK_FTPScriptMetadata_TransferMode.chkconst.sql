ALTER TABLE [dbo].[FTPScriptMetadata]
	ADD CONSTRAINT [CK_FTPScriptMetadata_TransferMode] 
	CHECK  (TransferMode = 'ascii' OR TransferMode = 'binary')
