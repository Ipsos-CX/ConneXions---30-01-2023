ALTER TABLE [dbo].[Files]
    ADD CONSTRAINT [FK_Files_FileTypes] FOREIGN KEY ([FileTypeID]) REFERENCES [dbo].[FileTypes] ([FileTypeID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

