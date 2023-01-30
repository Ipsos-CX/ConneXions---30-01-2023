ALTER TABLE [dbo].[Files]
    ADD CONSTRAINT [DF_Files_AuditID] DEFAULT (0) FOR [AuditID];

