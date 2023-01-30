ALTER TABLE [dbo].[FTPScriptMetadata]
    ADD CONSTRAINT [DF_FTPScriptMetadata_Enabled] DEFAULT (0) FOR [Enabled];

