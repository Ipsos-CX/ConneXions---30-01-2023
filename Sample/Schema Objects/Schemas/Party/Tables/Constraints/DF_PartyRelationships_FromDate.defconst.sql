ALTER TABLE [Party].[PartyRelationships]
    ADD CONSTRAINT [DF_PartyRelationships_FromDate] DEFAULT (getdate()) FOR [FromDate];

