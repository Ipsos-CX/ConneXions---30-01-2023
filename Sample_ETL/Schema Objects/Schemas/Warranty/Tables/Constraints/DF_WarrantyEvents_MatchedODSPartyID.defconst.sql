ALTER TABLE [Warranty].[WarrantyEvents]
    ADD CONSTRAINT [DF_WarrantyEvents_MatchedODSPartyID] DEFAULT (0) FOR [MatchedODSPersonID];

