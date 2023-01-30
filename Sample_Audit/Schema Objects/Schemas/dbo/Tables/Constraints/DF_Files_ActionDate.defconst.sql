ALTER TABLE [dbo].[Files]
    ADD CONSTRAINT [DF_Files_ActionDate] DEFAULT (GETDATE()) FOR [ActionDate];

