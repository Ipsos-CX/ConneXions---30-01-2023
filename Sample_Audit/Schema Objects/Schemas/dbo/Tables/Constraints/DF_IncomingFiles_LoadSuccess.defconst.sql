ALTER TABLE [dbo].[IncomingFiles]
    ADD CONSTRAINT [DF_IncomingFiles_LoadSuccess] DEFAULT (0) FOR [LoadSuccess];

