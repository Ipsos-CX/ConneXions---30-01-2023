ALTER TABLE [dbo].[IncomingFiles]
    ADD CONSTRAINT [DF_IncomingFiles_AuditID] DEFAULT (0) FOR [AuditID];

