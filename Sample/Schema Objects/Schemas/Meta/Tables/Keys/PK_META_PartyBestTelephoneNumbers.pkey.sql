ALTER TABLE [Meta].[PartyBestTelephoneNumbers]
    ADD CONSTRAINT [PK_META_PartyBestTelephoneNumbers] PRIMARY KEY CLUSTERED ([PartyID] ASC) WITH (FILLFACTOR = 100, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

