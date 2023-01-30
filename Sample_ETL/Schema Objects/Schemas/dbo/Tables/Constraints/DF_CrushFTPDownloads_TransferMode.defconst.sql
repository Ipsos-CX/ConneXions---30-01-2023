ALTER TABLE [dbo].[CrushFTPDownloads]
    ADD CONSTRAINT [DF_CrushFTPDownloads_TransferMode] DEFAULT ('binary') FOR [TransferMode];

