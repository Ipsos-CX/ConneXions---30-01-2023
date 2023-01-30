ALTER TABLE [dbo].[CrushFTPDownloads]
	ADD CONSTRAINT [CK_CrushFTPDownloads_TransferMode] 
	CHECK  (TransferMode = 'ascii' OR TransferMode = 'binary')
