ALTER TABLE [Audit].[ContactPreferences]
    ADD CONSTRAINT [PK_ContactPreferences] 
    PRIMARY KEY CLUSTERED ([AuditItemID] ASC) WITH (FILLFACTOR = 90, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

