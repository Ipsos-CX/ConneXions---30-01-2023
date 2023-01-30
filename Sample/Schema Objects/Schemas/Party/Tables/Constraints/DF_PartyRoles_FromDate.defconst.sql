ALTER TABLE [Party].[PartyRoles]
    ADD CONSTRAINT [DF_PartyRoles_FromDate] DEFAULT (getdate()) FOR [FromDate];

