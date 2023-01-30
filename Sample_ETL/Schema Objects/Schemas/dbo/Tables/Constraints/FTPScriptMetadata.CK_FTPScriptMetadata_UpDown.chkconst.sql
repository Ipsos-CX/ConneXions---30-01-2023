ALTER TABLE [dbo].[FTPScriptMetadata]
	ADD CONSTRAINT [CK_FTPScriptMetadata_UpDown] 
	CHECK  (UpDown = 'U' OR UpDown = 'D')
