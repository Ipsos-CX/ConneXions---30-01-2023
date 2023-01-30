ALTER TABLE [Party].[Organisations]
    ADD CONSTRAINT [DF_Organisations_PartyID] DEFAULT (0) FOR [PartyID];

