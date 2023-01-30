ALTER TABLE [dbo].[CrushFTPDownloads]
    ADD CONSTRAINT [DF_CrushFTPDownloads_Enabled] DEFAULT (0) FOR [Enabled];

