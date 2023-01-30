ALTER TABLE [dbo].[FTPScriptMetadata]
    ADD CONSTRAINT [DF_FTPScriptMetadata_TransferMode] DEFAULT ('ascii') FOR [TransferMode];

