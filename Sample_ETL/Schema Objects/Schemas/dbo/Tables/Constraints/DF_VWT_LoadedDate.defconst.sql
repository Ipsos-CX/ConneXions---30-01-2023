ALTER TABLE [dbo].[VWT]
    ADD CONSTRAINT [DF_VWT_LoadedDate] DEFAULT (GETDATE()) FOR [LoadedDate];

