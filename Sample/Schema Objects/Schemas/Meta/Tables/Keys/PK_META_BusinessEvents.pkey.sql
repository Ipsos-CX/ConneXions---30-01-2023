ALTER TABLE [Meta].[BusinessEvents]
    ADD CONSTRAINT [PK_META_BusinessEvents] PRIMARY KEY CLUSTERED ([EventID] ASC) WITH (FILLFACTOR = 100, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

