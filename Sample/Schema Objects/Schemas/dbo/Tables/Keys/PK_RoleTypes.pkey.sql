ALTER TABLE [dbo].[RoleTypes]
    ADD CONSTRAINT [PK_RoleTypes] PRIMARY KEY CLUSTERED ([RoleTypeID] ASC) WITH (FILLFACTOR = 90, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

