ALTER TABLE [dbo].[CrushFTPDownloads]
    ADD CONSTRAINT [DF_CrushFTPDownloads_FilenameFilterMask] DEFAULT ('*.*') FOR [FilenameFilterMask];

