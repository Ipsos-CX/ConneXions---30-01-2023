ALTER TABLE [Party].[BlacklistStrings]
    ADD CONSTRAINT [PK_BlacklistStrings] PRIMARY KEY CLUSTERED ([BlacklistStringID] ASC) 
    WITH (FILLFACTOR = 90, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

