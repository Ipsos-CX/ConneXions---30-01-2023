ALTER TABLE [dbo].[OutgoingFiles]
    ADD CONSTRAINT [PK_OutgoingFiles] PRIMARY KEY CLUSTERED ([AuditID] ASC) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

